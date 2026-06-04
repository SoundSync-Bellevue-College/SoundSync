package models

type ServiceAlert struct {
	AlertID           string      `json:"alertId"`
	Agency            string      `json:"agency"`
	Effect            string      `json:"effect,omitempty"`
	Cause             string      `json:"cause,omitempty"`
	HeaderText        string      `json:"headerText,omitempty"`
	DescriptionText   string      `json:"descriptionText,omitempty"`
	SeverityLevel     string      `json:"severityLevel,omitempty"`
	ActivePeriodStart *int64      `json:"activePeriodStart,omitempty"`
	ActivePeriodEnd   *int64      `json:"activePeriodEnd,omitempty"`
	InformedEntities  interface{} `json:"informedEntities"`
	URL               string      `json:"url,omitempty"`
	LastSeen          string      `json:"lastSeen"`
}
