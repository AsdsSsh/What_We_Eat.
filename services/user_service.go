package services

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"

	"food-recommendation/config"
	"food-recommendation/database"
	"food-recommendation/models"
)

// 实现接口的具体类型
type userServiceImpl struct{}

func (u *userServiceImpl) GenerateToken(userID uint, deviceID string) (string, error) {
	cfg := config.LoadConfig()

	claims := jwt.MapClaims{
		"userId":   userID,
		"deviceId": deviceID,
		"exp":      time.Now().Add(time.Hour * 24 * 30).Unix(), // 30天过期
		"iat":      time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(cfg.JWTSecret))
}

func (u *userServiceImpl) CreateUserAsync(deviceID string) (*models.User, error) {
	db := database.GetDB()

	user := models.User{
		DeviceID:  deviceID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// 异步插入数据库
	go func() {
		if err := db.Create(&user).Error; err != nil {
			// 这里可以添加日志记录
			return
		}
	}()

	return &user, nil
}

func (u *userServiceImpl) GetOrCreateUserByDevice(deviceID string) (*models.User, error) {
	db := database.GetDB()

	var user models.User
	result := db.Where("device_id = ?", deviceID).First(&user)

	if result.Error == gorm.ErrRecordNotFound {
		// 创建新用户
		return u.CreateUserAsync(deviceID)
	}

	return &user, result.Error
}

func (u *userServiceImpl) GetUserChoices(userID uint) ([]models.UserChoice, error) {
	db := database.GetDB()

	var choices []models.UserChoice
	result := db.Where("user_id = ?", userID).Find(&choices)

	return choices, result.Error
}
