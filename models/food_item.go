package models

import (
	"time"
)

type FoodItem struct {
	ID          uint      `gorm:"primaryKey" json:"id"`      // 菜品唯一标识符
	Name        string    `json:"name"`                      // 菜品名称
	Description string    `json:"description"`               // 菜品描述
	Tags        []string  `gorm:"type:text[]" json:"tags"`   // 菜品标签（如：早餐、热汤等）
	Nutrition   Nutrition `gorm:"embedded" json:"nutrition"` // 菜品营养信息
	CreatedAt   time.Time `json:"createdAt"`                 // 菜品创建时间
	UpdatedAt   time.Time `json:"updatedAt"`                 // 菜品最后更新时间
}

type Nutrition struct {
	Protein  float64 `json:"protein"`  // 蛋白质含量
	Carbs    float64 `json:"carbs"`    // 碳水化合物含量
	Fat      float64 `json:"fat"`      // 脂肪含量
	Calories float64 `json:"calories"` // 热量
}
