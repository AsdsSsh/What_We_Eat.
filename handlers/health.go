package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"food-recommendation/database"
)

func HealthCheck(c *gin.Context) {
	// 检查数据库连接
	sqlDB, err := database.GetDB().DB()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "database error"})
		return
	}

	if err := sqlDB.Ping(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "database disconnected"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"time":    time.Now().Format(time.RFC3339),
		"service": "food-recommendation-api",
	})
}
