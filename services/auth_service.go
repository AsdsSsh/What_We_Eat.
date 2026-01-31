package services

import (
	"crypto/rand"
	"math/big"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"

	"food-recommendation/config"
	"food-recommendation/database"
	"food-recommendation/models"
)

type authServiceImpl struct{}

// GenerateVerificationCode 生成6位数验证码并存储
func (a *authServiceImpl) GenerateVerificationCode(email string) error {
	db := database.GetDB()

	// 生成6位随机验证码
	code, err := generateRandomCode(6)
	if err != nil {
		return err
	}

	// 删除该邮箱之前的验证码
	db.Where("email = ?", email).Delete(&models.VerificationCode{})

	// 创建新的验证码记录，5分钟后过期
	verificationCode := models.VerificationCode{
		Email:     email,
		Code:      code,
		ExpiresAt: time.Now().Add(5 * time.Minute),
		CreatedAt: time.Now(),
	}

	if err := db.Create(&verificationCode).Error; err != nil {
		return err
	}

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
	var verificationCode models.VerificationCode
	result := db.Where("email = ? AND code = ?", email, code).First(&verificationCode)
	if result.Error != nil {
		return nil, false, result.Error
	}

	// 检查是否过期
	if time.Now().After(verificationCode.ExpiresAt) {
		// 删除过期验证码
		db.Delete(&verificationCode)
		return nil, false, gorm.ErrRecordNotFound
	}

	// 验证成功，删除验证码
	db.Delete(&verificationCode)

	// 查找或创建用户
	var user models.User
	isNew := false
	result = db.Where("email = ?", email).First(&user)

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
func (a *authServiceImpl) GenerateTokenByEmail(userID uint, email string) (string, error) {
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
