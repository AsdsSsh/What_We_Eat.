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
	GetOrCreateUserByDevice(deviceID string) (*models.User, error)
	GetUserChoices(userID uint) ([]models.UserChoice, error)
	GenerateToken(userID uint, deviceID string) (string, error)
	CreateUserAsync(deviceID string) (*models.User, error)
}

// 全局服务实例
var (
	RecommendationRepo RecommendationService
	UserRepo           UserService
)

func InitServices() {
	RecommendationRepo = &recommendationServiceImpl{}
	UserRepo = &userServiceImpl{}
}
