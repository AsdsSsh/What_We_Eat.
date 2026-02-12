package services

import (
	"gorm.io/gorm"

	"food-recommendation/database"
	"food-recommendation/models"
)

// 实现接口的具体类型
type userServiceImpl struct{}

func (u *userServiceImpl) GetUserByEmail(email string) (*models.User, error) {
	db := database.GetDB()

	var user models.User
	result := db.Where("email = ?", email).First(&user)

	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}

	return &user, result.Error
}

func (u *userServiceImpl) GetUserChoices(userID string) ([]models.UserChoice, error) {
	db := database.GetDB()

	var choices []models.UserChoice
	result := db.Where("user_id = ?", userID).Find(&choices)

	return choices, result.Error
}
