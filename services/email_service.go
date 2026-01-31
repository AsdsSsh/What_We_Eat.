package services

import (
	"fmt"
	"net/smtp"

	"food-recommendation/config"
)

// EmailService 邮件服务接口
type EmailService interface {
	SendVerificationCode(toEmail, code string) error
}

type emailServiceImpl struct{}

var EmailRepo EmailService

func init() {
	EmailRepo = &emailServiceImpl{}
}

// SendVerificationCode 发送验证码邮件
func (e *emailServiceImpl) SendVerificationCode(toEmail, code string) error {
	cfg := config.LoadConfig()

	// 邮件主题和内容
	subject := "【今天吃什么】验证码"
	body := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
</head>
<body style="font-family: Arial, sans-serif; padding: 20px;">
    <div style="max-width: 600px; margin: 0 auto; background: #f9f9f9; padding: 30px; border-radius: 10px;">
        <h2 style="color: #333;">验证码</h2>
        <p style="color: #666;">您好！</p>
        <p style="color: #666;">您的验证码是：</p>
        <div style="background: #007bff; color: white; font-size: 32px; font-weight: bold; text-align: center; padding: 20px; border-radius: 5px; letter-spacing: 5px;">
            %s
        </div>
        <p style="color: #666; margin-top: 20px;">验证码有效期为 5 分钟，请尽快使用。</p>
        <p style="color: #999; font-size: 12px; margin-top: 30px;">如果这不是您的操作，请忽略此邮件。</p>
    </div>
</body>
</html>
`, code)

	// 构建邮件
	message := fmt.Sprintf("From: %s\r\n", cfg.SMTPFrom)
	message += fmt.Sprintf("To: %s\r\n", toEmail)
	message += fmt.Sprintf("Subject: %s\r\n", subject)
	message += "MIME-Version: 1.0\r\n"
	message += "Content-Type: text/html; charset=UTF-8\r\n"
	message += "\r\n"
	message += body

	// SMTP 认证
	auth := smtp.PlainAuth("", cfg.SMTPUser, cfg.SMTPPassword, cfg.SMTPHost)

	// 发送邮件
	addr := fmt.Sprintf("%s:%s", cfg.SMTPHost, cfg.SMTPPort)
	err := smtp.SendMail(addr, auth, cfg.SMTPFrom, []string{toEmail}, []byte(message))
	if err != nil {
		return fmt.Errorf("发送邮件失败: %w", err)
	}

	return nil
}
