package dto

type RegisterRequest struct {
	DeviceID string `json:"deviceId"`
}

type RecommendationRequest struct {
	UserID  uint   `json:"userId"`
	Weather string `json:"weather"`
	Time    string `json:"time"`
}

type DailyIntakeRequest struct {
	UserID uint     `json:"userId"`
	Foods  []string `json:"foods"`
}
