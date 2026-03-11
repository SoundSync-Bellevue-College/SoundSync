// Code generated from gtfs-realtime.proto — DO NOT EDIT.
// Regenerate with: protoc --go_out=. gtfs-realtime.proto
// This is a minimal hand-written stub for development use.
// Replace with generated output from the official transit_realtime.proto for production.

package transit_realtime

// OccupancyStatus mirrors the proto enum values.
type OccupancyStatus int32

const (
	OccupancyStatus_EMPTY                      OccupancyStatus = 0
	OccupancyStatus_MANY_SEATS_AVAILABLE       OccupancyStatus = 1
	OccupancyStatus_FEW_SEATS_AVAILABLE        OccupancyStatus = 2
	OccupancyStatus_STANDING_ROOM_ONLY         OccupancyStatus = 3
	OccupancyStatus_CRUSHED_STANDING_ROOM_ONLY OccupancyStatus = 4
	OccupancyStatus_FULL                       OccupancyStatus = 5
	OccupancyStatus_NOT_ACCEPTING_PASSENGERS   OccupancyStatus = 6
)

var occupancyNames = map[OccupancyStatus]string{
	0: "EMPTY",
	1: "MANY_SEATS_AVAILABLE",
	2: "FEW_SEATS_AVAILABLE",
	3: "STANDING_ROOM_ONLY",
	4: "CRUSHED_STANDING_ROOM_ONLY",
	5: "FULL",
	6: "NOT_ACCEPTING_PASSENGERS",
}

func (o OccupancyStatus) String() string {
	if s, ok := occupancyNames[o]; ok {
		return s
	}
	return "UNKNOWN"
}

// ─── Message structs ──────────────────────────────────────────────────────────

type FeedMessage struct {
	Header *FeedHeader   `protobuf:"bytes,1,req,name=header" json:"header,omitempty"`
	Entity []*FeedEntity `protobuf:"bytes,2,rep,name=entity" json:"entity,omitempty"`
}

func (m *FeedMessage) Reset()         {}
func (m *FeedMessage) String() string { return "" }
func (m *FeedMessage) ProtoMessage()  {}

type FeedHeader struct {
	GtfsRealtimeVersion *string `protobuf:"bytes,1,req,name=gtfs_realtime_version,json=gtfsRealtimeVersion" json:"gtfs_realtime_version,omitempty"`
	Timestamp           *uint64 `protobuf:"varint,2,opt,name=timestamp" json:"timestamp,omitempty"`
}

func (m *FeedHeader) Reset()         {}
func (m *FeedHeader) String() string { return "" }
func (m *FeedHeader) ProtoMessage()  {}

type FeedEntity struct {
	Id        *string          `protobuf:"bytes,1,req,name=id" json:"id,omitempty"`
	IsDeleted *bool            `protobuf:"varint,3,opt,name=is_deleted,json=isDeleted" json:"is_deleted,omitempty"`
	Vehicle   *VehiclePosition `protobuf:"bytes,4,opt,name=vehicle" json:"vehicle,omitempty"`
}

func (m *FeedEntity) Reset()         {}
func (m *FeedEntity) String() string { return "" }
func (m *FeedEntity) ProtoMessage()  {}

func (m *FeedEntity) GetVehicle() *VehiclePosition {
	if m != nil {
		return m.Vehicle
	}
	return nil
}

type VehiclePosition struct {
	Trip            *TripDescriptor    `protobuf:"bytes,1,opt,name=trip" json:"trip,omitempty"`
	Vehicle         *VehicleDescriptor `protobuf:"bytes,8,opt,name=vehicle" json:"vehicle,omitempty"`
	Position        *Position          `protobuf:"bytes,2,opt,name=position" json:"position,omitempty"`
	Timestamp       *uint64            `protobuf:"varint,5,opt,name=timestamp" json:"timestamp,omitempty"`
	OccupancyStatus *OccupancyStatus   `protobuf:"varint,9,opt,name=occupancy_status,json=occupancyStatus,enum=transit_realtime.OccupancyStatus" json:"occupancy_status,omitempty"`
}

func (m *VehiclePosition) Reset()         {}
func (m *VehiclePosition) String() string { return "" }
func (m *VehiclePosition) ProtoMessage()  {}

func (m *VehiclePosition) GetTrip() *TripDescriptor {
	if m != nil {
		return m.Trip
	}
	return nil
}

func (m *VehiclePosition) GetVehicle() *VehicleDescriptor {
	if m != nil {
		return m.Vehicle
	}
	return nil
}

func (m *VehiclePosition) GetPosition() *Position {
	if m != nil {
		return m.Position
	}
	return nil
}

type TripDescriptor struct {
	TripId  *string `protobuf:"bytes,1,opt,name=trip_id,json=tripId" json:"trip_id,omitempty"`
	RouteId *string `protobuf:"bytes,5,opt,name=route_id,json=routeId" json:"route_id,omitempty"`
}

func (m *TripDescriptor) Reset()         {}
func (m *TripDescriptor) String() string { return "" }
func (m *TripDescriptor) ProtoMessage()  {}

func (m *TripDescriptor) GetTripId() string {
	if m != nil && m.TripId != nil {
		return *m.TripId
	}
	return ""
}

func (m *TripDescriptor) GetRouteId() string {
	if m != nil && m.RouteId != nil {
		return *m.RouteId
	}
	return ""
}

type VehicleDescriptor struct {
	Id    *string `protobuf:"bytes,1,opt,name=id" json:"id,omitempty"`
	Label *string `protobuf:"bytes,2,opt,name=label" json:"label,omitempty"`
}

func (m *VehicleDescriptor) Reset()         {}
func (m *VehicleDescriptor) String() string { return "" }
func (m *VehicleDescriptor) ProtoMessage()  {}

func (m *VehicleDescriptor) GetId() string {
	if m != nil && m.Id != nil {
		return *m.Id
	}
	return ""
}

type Position struct {
	Latitude  *float32 `protobuf:"fixed32,1,req,name=latitude" json:"latitude,omitempty"`
	Longitude *float32 `protobuf:"fixed32,2,req,name=longitude" json:"longitude,omitempty"`
	Bearing   *float32 `protobuf:"fixed32,3,opt,name=bearing" json:"bearing,omitempty"`
	Speed     *float32 `protobuf:"fixed32,5,opt,name=speed" json:"speed,omitempty"`
}

func (m *Position) Reset()         {}
func (m *Position) String() string { return "" }
func (m *Position) ProtoMessage()  {}

func (m *Position) GetLatitude() float32 {
	if m != nil && m.Latitude != nil {
		return *m.Latitude
	}
	return 0
}

func (m *Position) GetLongitude() float32 {
	if m != nil && m.Longitude != nil {
		return *m.Longitude
	}
	return 0
}

func (m *Position) GetBearing() float32 {
	if m != nil && m.Bearing != nil {
		return *m.Bearing
	}
	return 0
}

func (m *Position) GetSpeed() float32 {
	if m != nil && m.Speed != nil {
		return *m.Speed
	}
	return 0
}
