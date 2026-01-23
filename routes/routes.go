package routes

import (
	"github.com/gin-gonic/gin"

	"food-recommendation/handlers"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// 健康检查
	r.GET("/health", handlers.HealthCheck)

	// API v1 路由组
	api := r.Group("/api")
	{
		// 用户相关
		userGroup := api.Group("/user")
		{
			userGroup.POST("/register", handlers.RegisterUser)
			userGroup.GET("/:deviceId", handlers.GetUserByDevice)
		}

		// 推荐相关
		recommendGroup := api.Group("/recommend")
		{
			recommendGroup.GET("/:userId", handlers.GetRecommendations)
			recommendGroup.POST("/analyze", handlers.AnalyzeDailyIntake)
		}

		// 数据更新
		api.GET("/check-update", handlers.CheckForUpdates)
	}

	return r
}
