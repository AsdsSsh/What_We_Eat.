package models

type NutritionTag struct {
	ID   uint   `gorm:"primaryKey" json:"id"` // 营养标签唯一标识符
	Name string `json:"name"`                 // 标签名称（如：高蛋白、高碳水等）
}
