package services

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"soundsync/api/internal/config"
)

type WeatherService struct {
	cfg    *config.Config
	client *http.Client
}

func NewWeatherService(cfg *config.Config) *WeatherService {
	return &WeatherService{
		cfg:    cfg,
		client: &http.Client{Timeout: 8 * time.Second},
	}
}

// resolveGrid performs the NWS points lookup and returns the hourlyForecast URL + city name.
func (s *WeatherService) resolveGrid(ctx context.Context, lat, lng float64) (hourlyURL, cityName string, err error) {
	pointsURL := fmt.Sprintf("https://api.weather.gov/points/%.4f,%.4f", lat, lng)
	pointsData, err := s.nwsGet(ctx, pointsURL)
	if err != nil {
		return "", "", fmt.Errorf("NWS points lookup: %w", err)
	}
	props, _ := pointsData["properties"].(map[string]interface{})
	hourlyURL, _ = props["forecastHourly"].(string)
	city, _ := props["relativeLocation"].(map[string]interface{})
	cityProps, _ := city["properties"].(map[string]interface{})
	cityName, _ = cityProps["city"].(string)
	if hourlyURL == "" {
		return "", "", fmt.Errorf("NWS did not return a forecastHourly URL")
	}
	return hourlyURL, cityName, nil
}

// GetWeather fetches current conditions from the National Weather Service API.
// No API key required — US coverage only (fine for Seattle).
// Two-step: /points/{lat},{lng} → forecastHourly URL → first period.
func (s *WeatherService) GetWeather(ctx context.Context, lat, lng float64) (map[string]interface{}, error) {
	hourlyURL, cityName, err := s.resolveGrid(ctx, lat, lng)
	if err != nil {
		return nil, err
	}

	forecastData, err := s.nwsGet(ctx, hourlyURL)
	if err != nil {
		return nil, fmt.Errorf("NWS hourly forecast: %w", err)
	}

	fProps, _ := forecastData["properties"].(map[string]interface{})
	periods, _ := fProps["periods"].([]interface{})
	if len(periods) == 0 {
		return nil, fmt.Errorf("NWS returned no forecast periods")
	}

	p, _ := periods[0].(map[string]interface{})
	temp, _ := p["temperature"].(float64)
	windSpeed, _ := p["windSpeed"].(string)
	windDir, _ := p["windDirection"].(string)
	shortForecast, _ := p["shortForecast"].(string)
	detailedForecast, _ := p["detailedForecast"].(string)
	iconURL, _ := p["icon"].(string)
	isDaytime, _ := p["isDaytime"].(bool)

	return map[string]interface{}{
		"temp":             temp,
		"description":      shortForecast,
		"detailedForecast": detailedForecast,
		"windSpeed":        windSpeed,
		"windDirection":    windDir,
		"iconUrl":          iconURL,
		"isDaytime":        isDaytime,
		"cityName":         cityName,
		"timestamp":        time.Now().UTC().Format(time.RFC3339),
	}, nil
}

// GetHourlyForecast returns up to 12 hourly periods for the given coordinates.
func (s *WeatherService) GetHourlyForecast(ctx context.Context, lat, lng float64) (map[string]interface{}, error) {
	hourlyURL, cityName, err := s.resolveGrid(ctx, lat, lng)
	if err != nil {
		return nil, err
	}

	forecastData, err := s.nwsGet(ctx, hourlyURL)
	if err != nil {
		return nil, fmt.Errorf("NWS hourly forecast: %w", err)
	}

	fProps, _ := forecastData["properties"].(map[string]interface{})
	rawPeriods, _ := fProps["periods"].([]interface{})
	if len(rawPeriods) == 0 {
		return nil, fmt.Errorf("NWS returned no forecast periods")
	}

	limit := 12
	if len(rawPeriods) < limit {
		limit = len(rawPeriods)
	}

	periods := make([]map[string]interface{}, 0, limit)
	for _, raw := range rawPeriods[:limit] {
		p, _ := raw.(map[string]interface{})
		temp, _ := p["temperature"].(float64)
		periods = append(periods, map[string]interface{}{
			"number":        p["number"],
			"startTime":     p["startTime"],
			"temperature":   temp,
			"windSpeed":     p["windSpeed"],
			"windDirection": p["windDirection"],
			"shortForecast": p["shortForecast"],
			"iconUrl":       p["icon"],
			"isDaytime":     p["isDaytime"],
		})
	}

	return map[string]interface{}{
		"cityName": cityName,
		"periods":  periods,
	}, nil
}

// nwsGet performs a GET to the NWS API with the required User-Agent header.
func (s *WeatherService) nwsGet(ctx context.Context, url string) (map[string]interface{}, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	// NWS requires a descriptive User-Agent or requests may be rejected
	req.Header.Set("User-Agent", "SoundSyncAI/1.0 (transit-app; contact@soundsyncai.example)")
	req.Header.Set("Accept", "application/geo+json")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("NWS returned status %d for %s", resp.StatusCode, url)
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}
	return result, nil
}
