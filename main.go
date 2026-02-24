package main

import (
	"fmt"
	"food-recommendation/database"
	"food-recommendation/routes"
	"food-recommendation/services"
	"log"

	"food-recommendation/cache"
)

func main() {
	// 初始化数据库
	database.InitDB()

	// 初始化服务
	services.InitServices()

	// 创建并启动服务器
	router := routes.SetupRouter()

	// 初始化验证码缓存
	cache.GetVerificationCodeCache()

	port := ":8080"
	fmt.Printf("Server starting on port %s\n", port)
	if err := router.Run(port); err != nil {
		log.Fatal(err)
	}
}
