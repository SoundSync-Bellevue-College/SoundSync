package api

import (
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"
)

type commonReportFilter struct {
	RouteID     string
	StopID      string
	DirectionID *int
	Limit       int64
}

func parseCommonReportFilter(r *http.Request) (commonReportFilter, error) {
	q := r.URL.Query()
	filter := commonReportFilter{
		RouteID: q.Get("routeId"),
		StopID:  q.Get("stopId"),
	}

	if direction := strings.TrimSpace(q.Get("directionId")); direction != "" {
		d, err := strconv.Atoi(direction)
		if err != nil {
			return commonReportFilter{}, errors.New("directionId must be an integer")
		}
		filter.DirectionID = &d
	}

	if limitText := strings.TrimSpace(q.Get("limit")); limitText != "" {
		limit, err := strconv.ParseInt(limitText, 10, 64)
		if err != nil {
			return commonReportFilter{}, errors.New("limit must be an integer")
		}
		filter.Limit = limit
	}

	return filter, nil
}

func parseOptionalReportTime(value string) (time.Time, error) {
	if strings.TrimSpace(value) == "" {
		return time.Time{}, nil
	}
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		return time.Time{}, errors.New("report_time must be RFC3339")
	}
	return parsed, nil
}
