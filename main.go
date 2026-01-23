package main

import (
	"fmt"
	"log"

	"food-recommendation/database"
	"food-recommendation/routes"
	"food-recommendation/services"
)

func main() {
	// 初始化数据库
	database.InitDB()

	// 初始化服务
	services.InitServices()

	// 创建并启动服务器
	router := routes.SetupRouter()

	port := ":8080"
	fmt.Printf("Server starting on port %s\n", port)
	if err := router.Run(port); err != nil {
		log.Fatal(err)
	}
}
