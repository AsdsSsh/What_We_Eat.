package dto

// 验证码发送响应
type VerificationCodeResponse struct {
	Message string `json:"message"`
}

// 验证码验证响应
type VerifyCodeResponse struct {
	UserID  uint   `json:"userId"`
	Email   string `json:"email"`
	Token   string `json:"token"`
	Message string `json:"message"`
	IsNew   bool   `json:"isNew"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}
