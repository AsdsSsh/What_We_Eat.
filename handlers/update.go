package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"food-recommendation/database"
	"food-recommendation/models"
)

func CheckForUpdates(c *gin.Context) {
	lastUpdate := c.Query("lastUpdate")

	db := database.GetDB()

	// 检查是否有新菜品
	var newFoods []models.FoodItem
	query := db.Model(&models.FoodItem{})

	if lastUpdate != "" {
		parsedTime, err := time.Parse(time.RFC3339, lastUpdate)
		if err == nil {
			query = query.Where("created_at > ? OR updated_at > ?", parsedTime, parsedTime)
		}
	}

	query.Limit(20).Find(&newFoods)

	hasUpdate := len(newFoods) > 0

	c.JSON(http.StatusOK, gin.H{
		"hasUpdate":   hasUpdate,
		"newItems":    len(newFoods),
		"items":       newFoods,
		"lastChecked": time.Now().Format(time.RFC3339),
		"message":     fmt.Sprintf("发现%d个新菜品", len(newFoods)),
	})
}
