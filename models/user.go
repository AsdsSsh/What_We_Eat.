package models

import (
	"time"
)

type User struct {
	ID             string    `gorm:"primaryKey" json:"id"`     // 用户唯一标识符
	Email          string    `gorm:"uniqueIndex" json:"email"` // 用户邮箱
	Name           string    `json:"name"`                     // 用户名称
	CreatedAt      time.Time `json:"createdAt"`                // 用户创建时间
	UpdatedAt      time.Time `json:"updatedAt"`                // 用户信息最后更新时间
	PreferenceTags []string  `gorm:"-" json:"preferenceTags"`  // 用户偏好标签（不存储在数据库中）
}

// 验证码存储模型
type VerificationCode struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	Email     string    `gorm:"index" json:"email"` // 邮箱
	Code      string    `json:"code"`               // 验证码
	ExpiresAt time.Time `json:"expiresAt"`          // 过期时间
	CreatedAt time.Time `json:"createdAt"`          // 创建时间
}
