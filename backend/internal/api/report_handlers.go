package api

import (
	"encoding/json"
	"net/http"

	"soundsync/backend/internal/reports"
)

type createDelayReportRequest struct {
	RouteID     string `json:"routeId"`
	StopID      string `json:"stopId"`
	DirectionID int    `json:"directionId"`
	VehicleID   string `json:"vehicle_id"`
	ReportTime  string `json:"report_time"`
	DelayMinute int    `json:"delay_minutes"`
}

func (h *Handler) createDelayReport(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.authorize(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req createDelayReportRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON payload")
		return
	}

	reportTime, err := parseOptionalReportTime(req.ReportTime)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	report, err := h.delayRepo.Create(userID, reports.CreateDelayReportInput{
		RouteID:     req.RouteID,
		StopID:      req.StopID,
		DirectionID: req.DirectionID,
		VehicleID:   req.VehicleID,
		ReportTime:  reportTime,
		DelayMinute: req.DelayMinute,
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{"delay_report": report})
}

func (h *Handler) listDelayReports(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.authorize(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	f, err := parseCommonReportFilter(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	reportsList, err := h.delayRepo.List(reports.DelayReportFilter(f))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list delay reports")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"delay_reports": reportsList})
}

type createCrowdingReportRequest struct {
	RouteID       string `json:"routeId"`
	StopID        string `json:"stopId"`
	DirectionID   int    `json:"directionId"`
	VehicleID     string `json:"vehicle_id"`
	ReportTime    string `json:"report_time"`
	CrowdingLevel int    `json:"crowding_level"`
}

func (h *Handler) createCrowdingReport(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.authorize(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req createCrowdingReportRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON payload")
		return
	}

	reportTime, err := parseOptionalReportTime(req.ReportTime)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	report, err := h.crowdingRepo.Create(userID, reports.CreateCrowdingReportInput{
		RouteID:       req.RouteID,
		StopID:        req.StopID,
		DirectionID:   req.DirectionID,
		VehicleID:     req.VehicleID,
		ReportTime:    reportTime,
		CrowdingLevel: req.CrowdingLevel,
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{"crowding_report": report})
}

func (h *Handler) listCrowdingReports(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.authorize(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	f, err := parseCommonReportFilter(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	reportsList, err := h.crowdingRepo.List(reports.CrowdingReportFilter(f))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list crowding reports")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"crowding_reports": reportsList})
}

type createCleanlinessReportRequest struct {
	RouteID          string `json:"routeId"`
	StopID           string `json:"stopId"`
	DirectionID      int    `json:"directionId"`
	VehicleID        string `json:"vehicle_id"`
	ReportTime       string `json:"report_time"`
	CleanlinessLevel int    `json:"cleanliness_level"`
}

func (h *Handler) createCleanlinessReport(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.authorize(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req createCleanlinessReportRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON payload")
		return
	}

	reportTime, err := parseOptionalReportTime(req.ReportTime)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	report, err := h.cleanRepo.Create(userID, reports.CreateCleanlinessReportInput{
		RouteID:          req.RouteID,
		StopID:           req.StopID,
		DirectionID:      req.DirectionID,
		VehicleID:        req.VehicleID,
		ReportTime:       reportTime,
		CleanlinessLevel: req.CleanlinessLevel,
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{"cleanliness_report": report})
}

func (h *Handler) listCleanlinessReports(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.authorize(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	f, err := parseCommonReportFilter(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	reportsList, err := h.cleanRepo.List(reports.CleanlinessReportFilter(f))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list cleanliness reports")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"cleanliness_reports": reportsList})
}
