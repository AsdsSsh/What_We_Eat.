package models

import (
	"time"
)

type UserChoice struct {
	ID        uint      `gorm:"primaryKey" json:"id"` // 用户选择的唯一标识符
	UserID    uint      `json:"userId"`               // 关联的用户ID
	FoodID    uint      `json:"foodId"`               // 选择的菜品ID
	MealType  string    `json:"mealType"`             // 餐类型（如：早餐、午餐、晚餐）
	ChosenAt  time.Time `json:"chosenAt"`             // 选择时间
	CreatedAt time.Time `json:"createdAt"`            // 记录创建时间
}
