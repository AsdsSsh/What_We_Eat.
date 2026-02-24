package services

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"

	"food-recommendation/cache"
	"food-recommendation/config"
	"food-recommendation/database"
	"food-recommendation/models"
)

type authServiceImpl struct{}

// GenerateVerificationCode 生成6位数验证码并存储
func (a *authServiceImpl) GenerateVerificationCode(email string) error {

	// 生成6位随机验证码
	code, err := generateRandomCode(6)
	if err != nil {
		return err
	}
	cache.AddVerificationCode(email, code)

	// 发送验证码邮件
	if err := EmailRepo.SendVerificationCode(email, code); err != nil {
		return err
	}

	return nil
}

// VerifyCode 验证验证码并登录/注册用户
// 返回: 用户, 是否新用户, 错误
func (a *authServiceImpl) VerifyCode(email, code string) (*models.User, bool, error) {
	db := database.GetDB()

	// 查找验证码
	cachedCode, exists := cache.GetVerificationCode(email)
	if !exists || cachedCode != code {
		return nil, false, fmt.Errorf("invalid or expired verification code")
	}
	// 验证成功，删除验证码
	cache.DeleteVerificationCode(email)

	// 查找或创建用户
	var user models.User
	isNew := false
	result := db.Where("email = ?", email).First(&user)

	if result.Error == gorm.ErrRecordNotFound {
		// 创建新用户
		user = models.User{
			Email:     email,
			Name:      "HaveYouEatUser",
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}
		if err := db.Create(&user).Error; err != nil {
			return nil, false, err
		}
		isNew = true
	} else if result.Error != nil {
		return nil, false, result.Error
	}

	return &user, isNew, nil
}

// GenerateTokenByEmail 根据邮箱生成JWT token
func (a *authServiceImpl) GenerateTokenByEmail(userID string, email string) (string, error) {
	cfg := config.LoadConfig()

	claims := jwt.MapClaims{
		"userId": userID,
		"email":  email,
		"exp":    time.Now().Add(time.Hour * 24 * 30).Unix(), // 30天过期
		"iat":    time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(cfg.JWTSecret))
}

// generateRandomCode 生成指定长度的随机数字验证码
func generateRandomCode(length int) (string, error) {
	const digits = "0123456789"
	code := make([]byte, length)

	for i := 0; i < length; i++ {
		num, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
		if err != nil {
			return "", err
		}
		code[i] = digits[num.Int64()]
	}

	return string(code), nil
}

// ParseToken 解析JWT token，返回用户ID和邮箱
func (a *authServiceImpl) ParseToken(tokenString string) (jwt.MapClaims, error) {
	if tokenString == "" {
		return nil, fmt.Errorf("token不能为空")
	}
	cfg := config.LoadConfig()

	token, err := jwt.Parse(tokenString, func(t *jwt.Token) (interface{}, error) {
		if t.Method != jwt.SigningMethodHS256 {
			return nil, fmt.Errorf("unexpected signing method")
		}
		return []byte(cfg.JWTSecret), nil
	})
	if err != nil || !token.Valid {
		return nil, fmt.Errorf("invalid token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, fmt.Errorf("invalid claims")
	}
	return claims, nil
}
