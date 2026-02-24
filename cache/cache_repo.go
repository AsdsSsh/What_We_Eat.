package cache

// 单例
func GetVerificationCodeCache() VerificationCodeCache {
	verificationCodeCacheOnce.Do(func() {
		verificationCodeCacheInstance = NewVerificationCodeCache()
	})
	return verificationCodeCacheInstance
}
