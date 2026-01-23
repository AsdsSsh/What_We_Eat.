package dto

type RegisterResponse struct {
	UserID   uint   `json:"userId"`
	DeviceID string `json:"deviceId"`
	Token    string `json:"token"`
	Message  string `json:"message"`
	IsNew    bool   `json:"isNew"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}
