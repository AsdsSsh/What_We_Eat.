package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"food-recommendation/dto"
	"food-recommendation/services"
)

// GetVerificationCode 获取验证码接口
// GET /api/login_or_register?email=xxx
func GetVerificationCode(c *gin.Context) {
	var req dto.GetVerificationCodeRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse{Error: "邮箱格式不正确"})
		return
	}

	err := services.AuthRepo.GenerateVerificationCode(req.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse{Error: "生成验证码失败"})
		return
	}
	c.JSON(http.StatusOK, dto.VerificationCodeResponse{
		Message: "验证码已发送",
	})
}

// VerifyCode 验证验证码并登录/注册
// POST /api/verify_code
func VerifyCode(c *gin.Context) {
	var req dto.VerifyCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse{Error: "请求参数不正确"})
		return
	}

	user, isNew, err := services.AuthRepo.VerifyCode(req.Email, req.Code)
	if err != nil {
		c.JSON(http.StatusBadRequest, dto.ErrorResponse{Error: "验证码无效或已过期"})
		return
	}

	// 生成 token
	token, err := services.AuthRepo.GenerateTokenByEmail(user.ID, user.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.ErrorResponse{Error: "生成token失败"})
		return
	}

	message := "登录成功"
	if isNew {
		message = "注册成功"
	}

	c.JSON(http.StatusOK, dto.VerifyCodeResponse{
		UserID:  user.ID,
		Email:   user.Email,
		Token:   token,
		Message: message,
		IsNew:   isNew,
	})
}
