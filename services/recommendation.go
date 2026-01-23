package services

import (
	"time"

	"food-recommendation/database"
	"food-recommendation/models"
)

// 实现接口的具体类型
type recommendationServiceImpl struct{}

func (r *recommendationServiceImpl) GetScenarioBasedRecommendations(userID uint, weather, timeOfDay string, history []models.UserChoice) []models.FoodItem {
	var foods []models.FoodItem

	currentHour := time.Now().Hour()

	db := database.GetDB()

	query := db.Model(&models.FoodItem{})

	// 使用传入的 timeOfDay 参数，而不是重新获取时间
	if timeOfDay == "" {
		// 如果没有提供时间，使用当前时间
		currentHour = time.Now().Hour()
	} else {
		// 这里可以根据 timeOfDay 参数进行处理
		// 简化处理，直接使用当前时间
		currentHour = time.Now().Hour()
	}

	// 时间过滤
	if currentHour >= 6 && currentHour < 10 {
		query = query.Where("'早餐' = ANY(tags)")
	} else if currentHour >= 11 && currentHour < 14 {
		query = query.Where("'午餐' = ANY(tags)")
	} else if currentHour >= 17 && currentHour < 21 {
		query = query.Where("'晚餐' = ANY(tags)")
	}

	// 天气过滤
	if weather == "cold" || weather == "winter" {
		query = query.Where("'热汤' = ANY(tags)")
	}

	// 获取推荐结果
	query.Limit(10).Find(&foods)

	return foods
}

func (r *recommendationServiceImpl) AnalyzeUserPreference(choices []models.UserChoice) []string {
	tagCount := make(map[string]int)

	db := database.GetDB()

	for _, choice := range choices {
		var food models.FoodItem
		db.First(&food, choice.FoodID)

		for _, tag := range food.Tags {
			tagCount[tag]++
		}
	}

	// 返回前3个最常选择的标签
	var preferences []string
	for i := 0; i < 3 && len(tagCount) > 0; i++ {
		maxTag := ""
		maxCount := 0

		for tag, count := range tagCount {
			if count > maxCount {
				maxCount = count
				maxTag = tag
			}
		}

		if maxTag != "" {
			preferences = append(preferences, maxTag)
			delete(tagCount, maxTag)
		}
	}

	return preferences
}

func (r *recommendationServiceImpl) GetDinnerRecommendations(totalNutrition models.Nutrition) []models.FoodItem {
	var recommendations []models.FoodItem

	db := database.GetDB()

	// 示例逻辑：如果碳水摄入过多，过滤掉高碳水食物
	if totalNutrition.Carbs > 100 {
		db.Where("NOT '高碳水' = ANY(tags)").Limit(5).Find(&recommendations)
	} else {
		db.Limit(5).Find(&recommendations)
	}

	return recommendations
}
