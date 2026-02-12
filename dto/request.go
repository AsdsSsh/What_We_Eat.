package dto

// 获取验证码请求（通过 query 参数）
type GetVerificationCodeRequest struct {
	Email string `form:"email" binding:"required"`
}

// 验证码验证请求
type VerifyCodeRequest struct {
	Email string `json:"email" binding:"required"`
	Code  string `json:"code" binding:"required"`
}

type RecommendationRequest struct {
	UserID  string `json:"userId"`
	Weather string `json:"weather"`
	Time    string `json:"time"`
}

type DailyIntakeRequest struct {
	UserID string   `json:"userId"`
	Foods  []string `json:"foods"`
}
