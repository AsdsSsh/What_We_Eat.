package database

import (
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"food-recommendation/config"
	"food-recommendation/models"
)

var DB *gorm.DB

func InitDB() {
	cfg := config.LoadConfig()

	dsn := buildDSN(cfg)

	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// 自动迁移（根据模型创建表）
	err = DB.AutoMigrate(
		&models.User{},
		&models.FoodItem{},
		&models.UserChoice{},
		&models.NutritionTag{},
		&models.VerificationCode{},
	)

	if err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	log.Println("Database connected successfully")
}

func buildDSN(cfg config.Config) string {
	return "host=" + cfg.DBHost +
		" user=" + cfg.DBUser +
		" password=" + cfg.DBPassword +
		" dbname=" + cfg.DBName +
		" port=" + cfg.DBPort +
		" sslmode=disable"
}

func GetDB() *gorm.DB {
	return DB
}
