package models

type FoodItem struct {
	ID          uint     `gorm:"primaryKey" json:"id"`         // 菜品唯一标识符
	Name        string   `json:"name"`                         // 菜品名称
	Description string   `json:"description"`                  // 菜品描述
	Tags        []string `gorm:"type:text[]" json:"tags"`      // 菜品标签（如：早餐、热汤等）
	Nutrition   []string `gorm:"type:text[]" json:"nutrition"` // 菜品营养信息
}

func (FoodItem) TableName() string {
	return "food_items"
}
