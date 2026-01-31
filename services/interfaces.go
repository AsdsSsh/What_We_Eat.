package services

import (
	"food-recommendation/models"
)

// 定义服务接口，避免循环依赖
type RecommendationService interface {
	GetScenarioBasedRecommendations(userID uint, weather, timeOfDay string, history []models.UserChoice) []models.FoodItem
	AnalyzeUserPreference(choices []models.UserChoice) []string
	GetDinnerRecommendations(totalNutrition models.Nutrition) []models.FoodItem
}

type UserService interface {
	GetUserByEmail(email string) (*models.User, error)
	GetUserChoices(userID uint) ([]models.UserChoice, error)
}

// 验证码服务接口
type AuthService interface {
	GenerateVerificationCode(email string) error
	VerifyCode(email, code string) (*models.User, bool, error)
	GenerateTokenByEmail(userID uint, email string) (string, error)
}

// 全局服务实例
var (
	RecommendationRepo RecommendationService
	UserRepo           UserService
	AuthRepo           AuthService
)

func InitServices() {
	RecommendationRepo = &recommendationServiceImpl{}
	UserRepo = &userServiceImpl{}
	AuthRepo = &authServiceImpl{}
}
