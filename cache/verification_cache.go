package cache

import (
	"sync"
	"time"

	"github.com/patrickmn/go-cache"
)

type VerificationCodeCache interface {
	AddVerificationCode(email string, code string)
	GetVerificationCode(email string) (string, bool)
	DeleteVerificationCode(email string)
}

type verificationCodeCacheImpl struct {
	store *cache.Cache
}

var (
	verificationCodeCacheInstance VerificationCodeCache
	verificationCodeCacheOnce     sync.Once
)

func NewVerificationCodeCache() VerificationCodeCache {
	cacheConfig := LoadCacheConfig()
	return &verificationCodeCacheImpl{
		store: cache.New(
			time.Duration(cacheConfig.VerificationCodeCacheNoExpiration)*time.Minute,
			time.Duration(cacheConfig.VerificationCodeCacheCleanupInterval)*time.Minute,
		),
	}
}

func (v *verificationCodeCacheImpl) AddVerificationCode(email string, code string) {
	v.store.Set(email, code, cache.DefaultExpiration)
}

func AddVerificationCode(email string, code string) {
	GetVerificationCodeCache().AddVerificationCode(email, code)
}

func (v *verificationCodeCacheImpl) GetVerificationCode(email string) (string, bool) {
	code, found := v.store.Get(email)
	if found {
		return code.(string), true
	}
	return "", false
}

func GetVerificationCode(email string) (string, bool) {
	return GetVerificationCodeCache().GetVerificationCode(email)
}

func (v *verificationCodeCacheImpl) DeleteVerificationCode(email string) {
	v.store.Delete(email)
}

func DeleteVerificationCode(email string) {
	GetVerificationCodeCache().DeleteVerificationCode(email)
}
