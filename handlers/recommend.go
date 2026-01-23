package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"food-recommendation/models"
	"food-recommendation/services"
)

type RecommendationRequest struct {
	Weather string `json:"weather"`
	Time    string `json:"time"`
}

type DailyIntakeRequest struct {
	UserID uint     `json:"userId"`
	Foods  []string `json:"foods"`
}

func GetRecommendations(c *gin.Context) {
	userIdStr := c.Param("userId")
	userId, err := strconv.ParseUint(userIdStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户ID"})
		return
	}

	var req RecommendationRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		// 使用默认值
		req = RecommendationRequest{
			Weather: "default",
			Time:    "current",
		}
	}

	// 获取用户历史选择
	choices, err := services.UserRepo.GetUserChoices(uint(userId))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取用户历史失败"})
		return
	}

	// 获取推荐结果
	foods := services.RecommendationRepo.GetScenarioBasedRecommendations(
		uint(userId),
		req.Weather,
		req.Time,
		choices,
	)

	// 分析用户偏好
	preferenceTags := services.RecommendationRepo.AnalyzeUserPreference(choices)

	c.JSON(http.StatusOK, gin.H{
		"userId":          userId,
		"recommendations": foods,
		"preferenceTags":  preferenceTags,
		"weather":         req.Weather,
		"time":            req.Time,
	})
}

func AnalyzeDailyIntake(c *gin.Context) {
	var req DailyIntakeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 分析已摄入的营养
	totalNutrition := models.Nutrition{}

	// 这里应该查询数据库获取食物营养信息
	// 简化处理

	// 获取晚餐推荐
	dinnerRecommendations := services.RecommendationRepo.GetDinnerRecommendations(totalNutrition)

	c.JSON(http.StatusOK, gin.H{
		"analysis": gin.H{
			"carbsExceeded": totalNutrition.Carbs > 100,
			"totalCarbs":    totalNutrition.Carbs,
			"message":       "今日碳水摄入已过量，建议晚餐选择清淡食物",
		},
		"recommendations": dinnerRecommendations,
	})
}
