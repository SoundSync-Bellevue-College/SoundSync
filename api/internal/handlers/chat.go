package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"soundsync/api/internal/config"
)

const anthropicMessagesURL = "https://api.anthropic.com/v1/messages"
const chatModel = "claude-haiku-4-5-20251001"

const transitSystemPrompt = `You are a helpful transit assistant for the greater Seattle/Bellevue area.
You help riders plan trips using King County Metro buses, Sound Transit Link Light Rail, ST Express buses,
Community Transit, and Pierce Transit. You have knowledge of major landmarks, neighborhoods, transit hubs,
and common routes in the Puget Sound region.

When helping with trip planning:
- Suggest practical routes with transfers if needed
- Mention key stops or stations along the way
- Note approximate travel times when you can estimate them
- Remind riders to check real-time arrivals for current schedules
- Be concise and friendly

If asked about something outside transit or the Seattle/Bellevue area, politely redirect to transit topics.`

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	Messages []chatMessage `json:"messages"`
}

type anthropicRequest struct {
	Model     string        `json:"model"`
	MaxTokens int           `json:"max_tokens"`
	System    string        `json:"system"`
	Messages  []chatMessage `json:"messages"`
}

type anthropicResponse struct {
	Content []struct {
		Type string `json:"type"`
		Text string `json:"text"`
	} `json:"content"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

type ChatHandler struct {
	apiKey string
}

func NewChatHandler(cfg *config.Config) *ChatHandler {
	return &ChatHandler{apiKey: cfg.AnthropicAPIKey}
}

func (h *ChatHandler) Chat(w http.ResponseWriter, r *http.Request) {
	if h.apiKey == "" {
		jsonError(w, "chatbot not configured", http.StatusServiceUnavailable)
		return
	}

	var req chatRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || len(req.Messages) == 0 {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}

	body, err := json.Marshal(anthropicRequest{
		Model:     chatModel,
		MaxTokens: 1024,
		System:    transitSystemPrompt,
		Messages:  req.Messages,
	})
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	httpReq, err := http.NewRequestWithContext(r.Context(), http.MethodPost, anthropicMessagesURL, bytes.NewReader(body))
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("x-api-key", h.apiKey)
	httpReq.Header.Set("anthropic-version", "2023-06-01")

	resp, err := http.DefaultClient.Do(httpReq)
	if err != nil {
		jsonError(w, fmt.Sprintf("upstream error: %v", err), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	respBytes, _ := io.ReadAll(resp.Body)
	var anthropicResp anthropicResponse
	if err := json.Unmarshal(respBytes, &anthropicResp); err != nil {
		jsonError(w, "failed to parse upstream response", http.StatusBadGateway)
		return
	}

	if anthropicResp.Error != nil {
		jsonError(w, anthropicResp.Error.Message, http.StatusBadGateway)
		return
	}

	if len(anthropicResp.Content) == 0 {
		jsonError(w, "empty response from model", http.StatusBadGateway)
		return
	}

	jsonOK(w, map[string]interface{}{
		"message": anthropicResp.Content[0].Text,
		"role":    "assistant",
	}, http.StatusOK)
}
