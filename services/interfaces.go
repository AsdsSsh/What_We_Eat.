package services

import (
	"food-recommendation/models"

	"github.com/golang-jwt/jwt/v5"
)

// 定义服务接口，避免循环依赖
type RecommendationService interface {
	GetRecommendations(userID string, month int, day int, hour int, isLoggedIn bool) []models.FoodItem
}

type UserService interface {
	GetUserByEmail(email string) (*models.User, error)
	GetUserChoices(userID string) ([]models.UserChoice, error)
}

// 验证码服务接口
type AuthService interface {
	GenerateVerificationCode(email string) error
	VerifyCode(email, code string) (*models.User, bool, error)
	GenerateTokenByEmail(userID string, email string) (string, error)
	ParseToken(tokenString string) (jwt.MapClaims, error)
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
