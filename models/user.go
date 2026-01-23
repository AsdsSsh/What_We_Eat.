package models

import (
	"time"
)

type User struct {
	ID             uint      `gorm:"primaryKey" json:"id"`        // 用户唯一标识符
	DeviceID       string    `gorm:"uniqueIndex" json:"deviceId"` // 设备唯一标识符
	CreatedAt      time.Time `json:"createdAt"`                   // 用户创建时间
	UpdatedAt      time.Time `json:"updatedAt"`                   // 用户信息最后更新时间
	PreferenceTags []string  `gorm:"-" json:"preferenceTags"`     // 用户偏好标签（不存储在数据库中）
}
