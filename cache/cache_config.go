package cache

type CacheConfig struct {
	VerificationCodeCacheNoExpiration    int // 验证码缓存永不过期
	VerificationCodeCacheCleanupInterval int // 验证码缓存清理间隔
}

func LoadCacheConfig() *CacheConfig {
	return &CacheConfig{
		VerificationCodeCacheNoExpiration:    5,  // 永不过期
		VerificationCodeCacheCleanupInterval: 10, // 不进行自动清理
	}
}
