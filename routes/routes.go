package routes

import (
	"github.com/gin-gonic/gin"

	"food-recommendation/handlers"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// 健康检查
	r.GET("/health", handlers.HealthCheck)

	// API
	api := r.Group("/api")
	{
		// 验证码登录/注册
		api.GET("/login_or_register", handlers.GetVerificationCode)
		api.POST("/verify_code", handlers.VerifyCode)

		// 推荐相关
		recommendGroup := api.Group("/recommend")
		{
			recommendGroup.POST("/basic_recommend", handlers.GetRecommendations)
			recommendGroup.POST("/call_ai", handlers.CallAI)
		}

		// 收藏相关
		FavoriteGroup := api.Group("/favorite")
		{
			FavoriteGroup.POST("/sync", handlers.FavoriteSync)
			FavoriteGroup.GET("/list", handlers.GetFavorites)
		}

		// 数据更新
		api.GET("/check-update", handlers.CheckForUpdates)
	}

	return r
}
