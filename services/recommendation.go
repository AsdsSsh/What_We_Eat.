package services

import (
	"food-recommendation/database"
	"food-recommendation/models"
)

// 实现接口的具体类型
type recommendationServiceImpl struct{}

func (r *recommendationServiceImpl) GetRecommendations(userID string, month int, day int, hour int, isLoggedIn bool) []models.FoodItem {
	// 基础规则推荐
	recommendedFoodList := BasicRule(month, day, hour)
	if isLoggedIn {

	}
	return recommendedFoodList
}

type recommendationRule struct {
	name string
	when func(month int, day int, hour int) bool
	tags []string
}

// 基础规则引擎
func BasicRule(month int, day int, hour int) []models.FoodItem {
	var foods []models.FoodItem

	rules := []recommendationRule{
		{
			name: "breakfast",
			when: func(_ int, _ int, h int) bool { return h >= 6 && h < 10 },
			tags: []string{"早餐"},
		},
		{
			name: "lunch",
			when: func(_ int, _ int, h int) bool { return h >= 11 && h < 14 },
			tags: []string{"午餐"},
		},
		{
			name: "dinner",
			when: func(_ int, _ int, h int) bool { return h >= 17 && h < 21 },
			tags: []string{"晚餐"},
		},
		{
			name: "late",
			when: func(_ int, _ int, h int) bool { return h >= 21 || h < 6 },
			tags: []string{"宵夜"},
		},
		{
			name: "early_spring",
			when: func(m int, _ int, _ int) bool { return m == 3 },
			tags: []string{"清淡", "回暖"},
		},
		{
			name: "mid_spring",
			when: func(m int, _ int, _ int) bool { return m == 4 },
			tags: []string{"时令", "鲜蔬"},
		},
		{
			name: "late_spring",
			when: func(m int, _ int, _ int) bool { return m == 5 },
			tags: []string{"清爽", "轻食"},
		},
		{
			name: "early_summer",
			when: func(m int, _ int, _ int) bool { return m == 6 },
			tags: []string{"清爽", "凉拌"},
		},
		{
			name: "peak_summer",
			when: func(m int, _ int, _ int) bool { return m == 7 },
			tags: []string{"解暑", "清凉"},
		},
		{
			name: "late_summer",
			when: func(m int, _ int, _ int) bool { return m == 8 },
			tags: []string{"清淡", "开胃"},
		},
		{
			name: "early_autumn",
			when: func(m int, _ int, _ int) bool { return m == 9 },
			tags: []string{"润燥", "温和"},
		},
		{
			name: "mid_autumn",
			when: func(m int, _ int, _ int) bool { return m == 10 },
			tags: []string{"滋补", "暖胃"},
		},
		{
			name: "late_autumn",
			when: func(m int, _ int, _ int) bool { return m == 11 },
			tags: []string{"温补", "热汤"},
		},
		{
			name: "early_winter",
			when: func(m int, _ int, _ int) bool { return m == 12 },
			tags: []string{"热汤", "暖胃"},
		},
		{
			name: "mid_winter",
			when: func(m int, _ int, _ int) bool { return m == 1 },
			tags: []string{"浓味", "驱寒"},
		},
		{
			name: "late_winter",
			when: func(m int, _ int, _ int) bool { return m == 2 },
			tags: []string{"暖身", "进补"},
		},
	}

	var activeTags []string
	for _, rule := range rules {
		if rule.when(0, day, hour) {
			activeTags = append(activeTags, rule.tags...)
			println("rule matched:", rule.name)
		}
		if rule.when(month, day, 0) {
			println("rule matched:", rule.name)
			activeTags = append(activeTags, rule.tags...)
		}
	}

	db := database.GetDB()
	query := db.Model(&models.FoodItem{})
	if len(activeTags) > 0 {
		query = query.Where("? = ANY(nutrition_tags)", activeTags[0])
		for _, tag := range activeTags[1:] {
			query = query.Or("? = ANY(nutrition_tags)", tag)
		}
	}

	query.Limit(10).Find(&foods)
	return foods
}
