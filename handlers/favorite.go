package handlers

import (
	"database/sql/driver"
	"fmt"
	"food-recommendation/database"
	"food-recommendation/dto"
	"food-recommendation/services"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// pgStringArray 实现 driver.Valuer 接口，将 []string 序列化为 PostgreSQL 数组字面量
type pgStringArray []string

func (a pgStringArray) Value() (driver.Value, error) {
	if a == nil {
		return nil, nil
	}
	parts := make([]string, len(a))
	for i, s := range a {
		escaped := strings.ReplaceAll(s, `\`, `\\`)
		escaped = strings.ReplaceAll(escaped, `"`, `\"`)
		parts[i] = fmt.Sprintf(`"%s"`, escaped)
	}
	return "{" + strings.Join(parts, ",") + "}", nil
}

func (a *pgStringArray) Scan(src interface{}) error {
	if src == nil {
		*a = nil
		return nil
	}
	var str string
	switch v := src.(type) {
	case string:
		str = v
	case []byte:
		str = string(v)
	default:
		return fmt.Errorf("pgStringArray.Scan: unsupported type %T", src)
	}
	str = strings.TrimPrefix(str, "{")
	str = strings.TrimSuffix(str, "}")
	if str == "" {
		*a = []string{}
		return nil
	}
	*a = strings.Split(str, ",")
	for i, s := range *a {
		(*a)[i] = strings.Trim(s, `"`)
	}
	return nil
}

type userChoiceRecord struct {
	ID        string        `gorm:"column:id;primaryKey"`
	UserID    string        `gorm:"column:user_id"`
	FoodID    pgStringArray `gorm:"column:food_id;type:varchar[]"`
	CreatedAt time.Time     `gorm:"column:created_at"`
}

func (userChoiceRecord) TableName() string {
	return "user_choices"
}

func FavoriteSync(c *gin.Context) {
	log.Println("收到收藏同步请求")
	sqlDB := database.GetDB()

	var req dto.FavoriteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("请求参数错误: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数不正确"})
		return
	}
	claims, err := services.AuthRepo.ParseToken(req.Token)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "无效的令牌"})
		return
	}
	userId, ok := claims["userId"].(string)
	if !ok {
		log.Println("令牌中缺少用户ID")
		c.JSON(http.StatusUnauthorized, gin.H{"error": "令牌中缺少用户ID"})
		return
	}

	userChoice := userChoiceRecord{
		ID:        userId,
		UserID:    userId,
		FoodID:    pgStringArray(req.FoodIDs),
		CreatedAt: time.Now(),
	}

	if err := sqlDB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("user_id = ?", userId).Delete(&userChoiceRecord{}).Error; err != nil {
			return err
		}
		if len(req.FoodIDs) == 0 {
			return nil
		}
		return tx.Create(&userChoice).Error
	}); err != nil {
		log.Printf("无法保存用户选择: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "无法保存用户选择"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"message": "收藏同步成功",
	})
}

// GetFavorites 获取用户收藏列表
// GET /api/favorite/list?userId=xxx
func GetFavorites(c *gin.Context) {
	userID := c.Query("userId")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "缺少userId参数"})
		return
	}

	db := database.GetDB()

	// 1. 从 user_choices 查出 food_id 数组
	var record userChoiceRecord
	if err := db.Where("user_id = ?", userID).First(&record).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusOK, gin.H{"favorites": []interface{}{}})
			return
		}
		log.Printf("查询用户收藏失败: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询收藏失败"})
		return
	}

	if len(record.FoodID) == 0 {
		c.JSON(http.StatusOK, gin.H{"favorites": []interface{}{}})
		return
	}

	// 2. 用 food_id 列表查 food_items 的名称
	type foodNameResult struct {
		ID   string `gorm:"column:id"`
		Name string `gorm:"column:name"`
	}
	var foods []foodNameResult
	if err := db.Table("food_items").Select("id, name").Where("id IN ?", []string(record.FoodID)).Find(&foods).Error; err != nil {
		log.Printf("查询菜品名称失败: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询菜品信息失败"})
		return
	}

	// 3. 组装返回
	type favoriteItem struct {
		FoodID string `json:"foodId"`
		Name   string `json:"name"`
	}
	result := make([]favoriteItem, 0, len(foods))
	for _, f := range foods {
		result = append(result, favoriteItem{FoodID: f.ID, Name: f.Name})
	}

	c.JSON(http.StatusOK, gin.H{"favorites": result})
}
