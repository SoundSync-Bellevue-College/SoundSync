// Package gtfs decodes GTFS-RT feeds (protobuf or JSON).
package gtfs

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/golang/protobuf/proto"

	"soundsync/api/internal/models"
	pb "soundsync/api/pkg/gtfs/transit_realtime"
)

// ParseVehiclePositions decodes a GTFS-RT VehiclePositions protobuf feed
// and returns a slice of VehiclePosition structs.
func ParseVehiclePositions(data []byte) ([]models.VehiclePosition, error) {
	var feed pb.FeedMessage
	if err := proto.Unmarshal(data, &feed); err != nil {
		return nil, fmt.Errorf("unmarshal GTFS-RT feed: %w", err)
	}

	vehicles := make([]models.VehiclePosition, 0, len(feed.Entity))
	for _, entity := range feed.Entity {
		v := entity.GetVehicle()
		if v == nil {
			continue
		}

		pos := v.GetPosition()
		trip := v.GetTrip()
		vehDesc := v.GetVehicle()

		var ts string
		if v.Timestamp != nil {
			ts = time.Unix(int64(*v.Timestamp), 0).UTC().Format(time.RFC3339)
		} else {
			ts = time.Now().UTC().Format(time.RFC3339)
		}

		var occupancy string
		if v.OccupancyStatus != nil {
			occupancy = v.OccupancyStatus.String()
		}

		vehicles = append(vehicles, models.VehiclePosition{
			VehicleID:       safeStr(vehDesc.GetId()),
			RouteID:         safeStr(trip.GetRouteId()),
			TripID:          safeStr(trip.GetTripId()),
			Lat:             float64(pos.GetLatitude()),
			Lng:             float64(pos.GetLongitude()),
			Bearing:         pos.GetBearing(),
			Speed:           pos.GetSpeed(),
			Timestamp:       ts,
			OccupancyStatus: occupancy,
		})
	}

	return vehicles, nil
}

// kcmFeed mirrors the GTFS-RT JSON structure published by King County Metro.
type kcmFeed struct {
	Entity []struct {
		Vehicle struct {
			Vehicle struct {
				ID    string `json:"id"`
				Label string `json:"label"`
			} `json:"vehicle"`
			Trip struct {
				RouteID     string `json:"route_id"`
				TripID      string `json:"trip_id"`
				DirectionID int    `json:"direction_id"`
			} `json:"trip"`
			Position struct {
				Latitude  float64 `json:"latitude"`
				Longitude float64 `json:"longitude"`
				Bearing   float32 `json:"bearing"`
				Speed     float32 `json:"speed"`
			} `json:"position"`
			Timestamp     int64  `json:"timestamp"`
			CurrentStatus string `json:"current_status"`
			StopID        string `json:"stop_id"`
		} `json:"vehicle"`
	} `json:"entity"`
}

// ParseVehiclePositionsJSON decodes a GTFS-RT JSON vehicle positions feed
// (e.g. from https://s3.amazonaws.com/kcm-alerts-realtime-prod/vehiclepositions_pb.json).
func ParseVehiclePositionsJSON(data []byte) ([]models.VehiclePosition, error) {
	var feed kcmFeed
	if err := json.Unmarshal(data, &feed); err != nil {
		return nil, fmt.Errorf("unmarshal GTFS-RT JSON feed: %w", err)
	}

	vehicles := make([]models.VehiclePosition, 0, len(feed.Entity))
	for _, entity := range feed.Entity {
		v := entity.Vehicle
		if v.Position.Latitude == 0 && v.Position.Longitude == 0 {
			continue // skip entries with no position
		}

		ts := time.Now().UTC().Format(time.RFC3339)
		if v.Timestamp > 0 {
			ts = time.Unix(v.Timestamp, 0).UTC().Format(time.RFC3339)
		}

		vehicles = append(vehicles, models.VehiclePosition{
			VehicleID:       v.Vehicle.ID,
			RouteID:         v.Trip.RouteID,
			TripID:          v.Trip.TripID,
			Lat:             v.Position.Latitude,
			Lng:             v.Position.Longitude,
			Bearing:         v.Position.Bearing,
			Speed:           v.Position.Speed,
			Timestamp:       ts,
			OccupancyStatus: v.CurrentStatus,
		})
	}

	return vehicles, nil
}

func safeStr(s string) string {
	return s
}
