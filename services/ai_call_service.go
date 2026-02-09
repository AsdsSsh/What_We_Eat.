package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"food-recommendation/config"
	"io"
	"net/http"
	"time"
)

type deepSeekResponse struct {
	ID      string `json:"id"`
	Created int64  `json:"created"`
	Model   string `json:"model"`
	Object  string `json:"object"`
	Choices []struct {
		FinishReason string `json:"finish_reason"`
		Index        int    `json:"index"`
		Message      struct {
			Content          string `json:"content"`
			ReasoningContent string `json:"reasoning_content"`
			ToolCalls        []struct {
				ID       string `json:"id"`
				Type     string `json:"type"`
				Function struct {
					Name      string `json:"name"`
					Arguments string `json:"arguments"`
				} `json:"function"`
			} `json:"tool_calls"`
			Role string `json:"role"`
		} `json:"message"`
		Logprobs struct {
			Content []struct {
				Token       string `json:"token"`
				Logprob     int    `json:"logprob"`
				Bytes       []int  `json:"bytes"`
				TopLogprobs []struct {
					Token   string `json:"token"`
					Logprob int    `json:"logprob"`
					Bytes   []int  `json:"bytes"`
				} `json:"top_logprobs"`
			} `json:"content"`
			ReasoningContent []struct {
				Token       string `json:"token"`
				Logprob     int    `json:"logprob"`
				Bytes       []int  `json:"bytes"`
				TopLogprobs []struct {
					Token   string `json:"token"`
					Logprob int    `json:"logprob"`
					Bytes   []int  `json:"bytes"`
				} `json:"top_logprobs"`
			} `json:"reasoning_content"`
		} `json:"logprobs"`
	} `json:"choices"`
	SystemFingerprint string `json:"system_fingerprint"`
	Usage             struct {
		CompletionTokens        int `json:"completion_tokens"`
		PromptTokens            int `json:"prompt_tokens"`
		PromptCacheHitTokens    int `json:"prompt_cache_hit_tokens"`
		PromptCacheMissTokens   int `json:"prompt_cache_miss_tokens"`
		TotalTokens             int `json:"total_tokens"`
		CompletionTokensDetails struct {
			ReasoningTokens int `json:"reasoning_tokens"`
		} `json:"completion_tokens_details"`
	} `json:"usage"`
}

type deepSeekResponseMessage struct {
	Content          string `json:"content"`
	ReasoningContent string `json:"reasoning_content"`
	ToolCalls        []struct {
		ID       string `json:"id"`
		Type     string `json:"type"`
		Function struct {
			Name      string `json:"name"`
			Arguments string `json:"arguments"`
		} `json:"function"`
	} `json:"tool_calls"`
	Role string `json:"role"`
}

// ...existing code...
type openWeatherResponse struct {
	Coord struct {
		Lon float64 `json:"lon"`
		Lat float64 `json:"lat"`
	} `json:"coord"`
	Weather []struct {
		ID          int    `json:"id"`
		Main        string `json:"main"`
		Description string `json:"description"`
		Icon        string `json:"icon"`
	} `json:"weather"`
	Base string `json:"base"`
	Main struct {
		Temp      float64 `json:"temp"`
		FeelsLike float64 `json:"feels_like"`
		TempMin   float64 `json:"temp_min"`
		TempMax   float64 `json:"temp_max"`
		Pressure  int     `json:"pressure"`
		Humidity  int     `json:"humidity"`
		SeaLevel  int     `json:"sea_level"`
		GrndLevel int     `json:"grnd_level"`
	} `json:"main"`
	Visibility int `json:"visibility"`
	Wind       struct {
		Speed float64 `json:"speed"`
		Deg   int     `json:"deg"`
	} `json:"wind"`
	Clouds struct {
		All int `json:"all"`
	} `json:"clouds"`
	Dt  int64 `json:"dt"`
	Sys struct {
		Type    int    `json:"type"`
		ID      int    `json:"id"`
		Country string `json:"country"`
		Sunrise int64  `json:"sunrise"`
		Sunset  int64  `json:"sunset"`
	} `json:"sys"`
	Timezone int         `json:"timezone"`
	ID       int         `json:"id"`
	Name     string      `json:"name"`
	Cod      json.Number `json:"cod"`
}

var authConfig config.Config = config.LoadConfig()

func buildPayload(message []map[string]any) (io.Reader, error) {
	body := map[string]any{
		"messages":          message,
		"model":             "deepseek-chat",
		"thinking":          map[string]string{"type": "disabled"},
		"frequency_penalty": 0,
		"max_tokens":        4096,
		"presence_penalty":  0,
		"response_format":   map[string]string{"type": "text"},
		"stop":              nil,
		"stream":            false,
		"stream_options":    nil,
		"temperature":       1,
		"top_p":             1,
		"tools":             tools,
		"tool_choice":       "auto",
		"logprobs":          false,
		"top_logprobs":      nil,
	}
	b, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	return bytes.NewReader(b), nil
}

func NewCLient() *http.Client {
	return &http.Client{}
}

func sendMessage(message []map[string]any, client *http.Client) (response deepSeekResponseMessage, err error) {
	url := authConfig.DeepseekURL
	method := "POST"
	payload, err := buildPayload(message)
	if err != nil {
		fmt.Println(err)
		return
	}
	req, err := http.NewRequest(method, url, payload)
	if err != nil {
		fmt.Println(err)
		return
	}
	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Authorization", "Bearer "+authConfig.DeepseekAPIKey)
	req.Header.Add("Accept", "application/json")
	res, err := client.Do(req)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer res.Body.Close()

	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("read body error:" + err.Error())
		return response, err
	}
	var parsed deepSeekResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		fmt.Println("unmarshal error:", err)
		return response, nil
	}
	if len(parsed.Choices) == 0 {
		fmt.Println("no choices, raw body:", string(body))
		return response, fmt.Errorf("no choices in response")
	}
	return parsed.Choices[0].Message, nil
}

func CallAI(message string, lon float64, lat float64, userId string) (response string) {
	messageMap := []map[string]any{
		{"content": "You are now an expert in food, providing users with advice about food. ", "role": "system"},
		{"content": "The user is currently at longitude " + fmt.Sprintf("%f", lon) + " and latitude " + fmt.Sprintf("%f", lat) + "." + "When latitude and longitude are not available or Empty string, inform the user:Location information (latitude/longitude) is required to provide weather-based recommendations. Please enable location permissions or manually provide your location.", "role": "system"},
		{"content": "The user's ID is " + userId + "." + "If the userId is not empty, fetch the user's historical record comprehensive analysis. If userId is null or Empty string , tell user because of unlogin you can not access his/her historical record, but remeber do not mention userId or Id", "role": "system"},
		{"content": message, "role": "user"},
	}
	// 最大循环次数，防止死循环调用工具
	maxLoops := 6
	// 参数校验失败重试次数上限
	invalidArgCount := 0
	const maxInvalidArgRetries = 2
	client := NewCLient()
	for i := 0; i < maxLoops; i++ {
		deepSeekResponse, err := sendMessage(messageMap, client)
		if err != nil {
			fmt.Println("sendMessage error:" + err.Error())
			return "Sorry, I'm having trouble processing your request right now."
		}
		fmt.Println("deepSeekResponse:", deepSeekResponse)
		tools := deepSeekResponse.ToolCalls
		if len(tools) != 0 {
			// 添加 assistant 消息上游
			messageMap = append(messageMap, map[string]any{
				"role":       "assistant",
				"content":    deepSeekResponse.Content,
				"tool_calls": tools,
			})
			for _, val := range tools {
				switch val.Function.Name {
				case "get_weather":
					var args struct {
						Lon float64 `json:"lon"`
						Lat float64 `json:"lat"`
					}
					if err := json.Unmarshal([]byte(val.Function.Arguments), &args); err != nil ||
						args.Lon < -180 || args.Lon > 180 || args.Lat < -90 || args.Lat > 90 {

						invalidArgCount++
						messageMap = append(messageMap, map[string]any{
							"role":         "tool",
							"tool_call_id": val.ID,
							"content":      "参数无效，请修正 lon/lat",
						})
						if invalidArgCount >= maxInvalidArgRetries {
							return "AI助手出现了一些问题,请稍候再试"
						}
						break
					}
					weather := get_weather(args.Lon, args.Lat)
					messageMap = append(messageMap, map[string]any{
						"role":         "tool",
						"tool_call_id": val.ID,
						"content":      weather,
					})
				case "get_current_time":
					currentTime := get_current_time()
					messageMap = append(messageMap, map[string]any{
						"role":         "tool",
						"tool_call_id": val.ID,
						"content":      currentTime,
					})
				case "get_user_history_and_preference":
					var args struct {
						UserId string `json:"user_id"`
					}
					if err := json.Unmarshal([]byte(val.Function.Arguments), &args); err != nil || args.UserId == "" {
						invalidArgCount++
						messageMap = append(messageMap, map[string]any{
							"role":         "tool",
							"tool_call_id": val.ID,
							"content":      "参数无效，请修正 user_id",
						})
						if invalidArgCount >= maxInvalidArgRetries {
							return "AI助手出现了一些问题,请稍候再试"
						}
						break

					}
					history := get_user_history_and_preference(args.UserId)
					messageMap = append(messageMap, map[string]any{
						"role":         "tool",
						"tool_call_id": val.ID,
						"content":      history,
					})
				}
			}
		} else {
			// 没有调用工具，直接返回结果
			return deepSeekResponse.Content

		}
	}
	return "Sorry, I'm having trouble processing your request right now."
}

func get_weather(lon float64, lat float64) (weather string) {
	url := fmt.Sprintf("https://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&appid=%s", lat, lon, authConfig.OpenWeatherKey)
	method := "GET"
	req, err := http.NewRequest(method, url, nil)
	if err != nil {
		fmt.Println(err)
		return
	}
	res, err := NewCLient().Do(req)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println(err)
		return
	}
	var parsed openWeatherResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		fmt.Println(err)
		return
	}
	if len(parsed.Weather) == 0 {
		return
	}
	fmt.Print(parsed.Weather)
	return fmt.Sprintf("%s", "The Main Weather: "+parsed.Weather[0].Main+", Description: "+parsed.Weather[0].Description)
}

func get_current_time() (currentTime string) {
	return fmt.Sprintf("%d", time.Now().Unix())
}

func get_user_history_and_preference(userId string) (history string) {
	return fmt.Sprintf("User %s has a history of ordering pizza and pasta, and prefers spicy food.", userId)
}

// Function calling 工具
var tools = []map[string]any{
	{
		"type": "function",
		"function": map[string]any{
			"name":        "get_weather",
			"description": "Get weather of a location, parameters lon and lat is needed.",
			"parameters": map[string]any{
				"type": "object",
				"properties": map[string]any{
					"lon": map[string]any{
						"type":        "number",
						"description": "The longitude of the location.",
					},
					"lat": map[string]any{
						"type":        "number",
						"description": "The latitude of the location.",
					},
				},
				"required": []string{"lon", "lat"},
			},
		},
	},
	{
		"type": "function",
		"function": map[string]any{
			"name":        "get_current_time",
			"description": "Get current time which is used to provide better recommendation, no parameter is needed. The time is in unix timestamp format. ",
			"parameters": map[string]any{
				"type":       "object",
				"properties": map[string]any{},
				"required":   []string{},
			},
		},
	},
	{
		"type": "function",
		"function": map[string]any{
			"name":        "get_user_history_and_preference",
			"description": "Get user history and preference for personalized recommendations, parameter required is user_id. The user_id is a string that uniquely identifies a user in the system. ",
			"parameters": map[string]any{
				"type": "object",
				"properties": map[string]any{
					"user_id": map[string]any{
						"type":        "string",
						"description": "The unique identifier of the user.",
					},
				},
				"required": []string{"user_id"},
			},
		},
	},
}
