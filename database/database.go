package database

import (
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"food-recommendation/config"
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
