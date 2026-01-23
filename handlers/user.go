package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"food-recommendation/services"
)

type RegisterRequest struct {
	DeviceID string `json:"deviceId" binding:"required"`
}

type RegisterResponse struct {
	UserID   uint   `json:"userId"`
	DeviceID string `json:"deviceId"`
	Token    string `json:"token"`
	Message  string `json:"message"`
	IsNew    bool   `json:"isNew"`
}

func RegisterUser(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "deviceId是必填项"})
		return
	}

	user, err := services.UserRepo.GetOrCreateUserByDevice(req.DeviceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "处理用户信息失败"})
		return
	}

	// 生成 token
	token, err := services.UserRepo.GenerateToken(user.ID, user.DeviceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "生成token失败"})
		return
	}

	// 判断是新用户还是已存在的用户
	isNew := user.ID == 0

	c.JSON(http.StatusOK, RegisterResponse{
		UserID:   user.ID,
		DeviceID: user.DeviceID,
		Token:    token,
		Message:  map[bool]string{true: "新用户注册成功", false: "用户已存在"}[isNew],
		IsNew:    isNew,
	})
}

func GetUserByDevice(c *gin.Context) {
	deviceId := c.Param("deviceId")

	user, err := services.UserRepo.GetOrCreateUserByDevice(deviceId)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取用户失败"})
		return
	}

	c.JSON(http.StatusOK, user)
}
