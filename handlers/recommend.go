package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"food-recommendation/models"
	"food-recommendation/services"
)

type RecommendationRequest struct {
	Month int `json:"month"`
	Day   int `json:"day"`
	Hour  int `json:"hour"`
}

type DailyIntakeRequest struct {
	UserID string   `json:"userId"`
	Foods  []string `json:"foods"`
}

type CallAIRequest struct {
	Message   string  `json:"message"`
	Lontitude float64 `json:"longitude"` // 经度
	Latitude  float64 `json:"latitude"`  // 纬度
	UserId    string  `json:"userId"`    // 用户ID ， 用于个性化推荐
}

type CallAIResponse struct {
	Response string `json:"response"`
}

func CallAI(c *gin.Context) {
	var req CallAIRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	response := services.CallAI(req.Message, req.Lontitude, req.Latitude, req.UserId)
	c.JSON(http.StatusOK, CallAIResponse{Response: response})
}

func GetRecommendations(c *gin.Context) {
	var req RecommendationRequest
	userIdStr := c.Param("token")
	claims, err := services.AuthRepo.ParseToken(userIdStr)
	isLoggedIn := true
	if err != nil {
		// 解析token失败， 只根据天气和时间推荐
		isLoggedIn = false
	}
	if err := c.ShouldBindQuery(&req); err != nil {
		// 使用当前时间作为默认值
		now := time.Now()
		req.Month = int(now.Month())
		req.Day = now.Day()
		req.Hour = now.Hour()
	}

	userID := ""
	if isLoggedIn {
		if id, ok := claims["userId"].(string); ok {
			userID = id
		}
	}

	recommendations := services.RecommendationRepo.GetRecommendations(userID, req.Month, req.Day, req.Hour, isLoggedIn)
	if recommendations == nil {
		recommendations = []models.FoodItem{}
	}

	c.JSON(http.StatusOK, gin.H{
		"recommendations": recommendations,
		"month":           req.Month,
		"day":             req.Day,
		"hour":            req.Hour,
		"isLoggedIn":      isLoggedIn,
	})
}
