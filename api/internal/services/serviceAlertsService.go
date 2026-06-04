package services

import (
	"context"
	"database/sql"
	"encoding/json"
	"time"

	"soundsync/api/internal/models"
)

type ServiceAlertsService struct {
	pg *sql.DB
}

func NewServiceAlertsService(pg *sql.DB) *ServiceAlertsService {
	return &ServiceAlertsService{pg: pg}
}

func (s *ServiceAlertsService) GetAlerts(ctx context.Context, agency string) ([]models.ServiceAlert, error) {
	now := time.Now().Unix()

	query := `
		SELECT alert_id, agency, effect, cause, header_text, description_text,
		       severity_level, active_period_start, active_period_end, informed_entity, url, last_seen
		FROM service_alerts
		WHERE (active_period_start IS NULL OR active_period_start <= $1)
		  AND (active_period_end   IS NULL OR active_period_end   >= $1)`

	args := []interface{}{now}
	if agency != "" {
		query += ` AND agency = $2`
		args = append(args, agency)
	}
	query += ` ORDER BY active_period_start DESC NULLS LAST`

	rows, err := s.pg.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var alerts []models.ServiceAlert
	for rows.Next() {
		var a models.ServiceAlert
		var effect, cause, header, description, severity, informedRaw, url sql.NullString
		var start, end sql.NullInt64
		var lastSeen time.Time

		if err := rows.Scan(
			&a.AlertID, &a.Agency,
			&effect, &cause, &header, &description, &severity,
			&start, &end, &informedRaw, &url, &lastSeen,
		); err != nil {
			return nil, err
		}

		a.Effect = effect.String
		a.Cause = cause.String
		a.HeaderText = header.String
		a.DescriptionText = description.String
		a.SeverityLevel = severity.String
		a.URL = url.String
		a.LastSeen = lastSeen.UTC().Format(time.RFC3339)

		if start.Valid {
			v := start.Int64
			a.ActivePeriodStart = &v
		}
		if end.Valid {
			v := end.Int64
			a.ActivePeriodEnd = &v
		}

		if informedRaw.Valid && informedRaw.String != "" {
			var entities interface{}
			if err := json.Unmarshal([]byte(informedRaw.String), &entities); err == nil {
				a.InformedEntities = entities
			}
		}

		alerts = append(alerts, a)
	}

	if alerts == nil {
		alerts = []models.ServiceAlert{}
	}
	return alerts, rows.Err()
}
