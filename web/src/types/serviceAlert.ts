export interface InformedEntity {
  agency_id?: string
  route_id?: string
  route_type?: number
  stop_id?: string
  activities?: string[]
}

export interface ServiceAlert {
  alertId: string
  agency: 'sound_transit' | 'king_county_metro'
  effect?: string
  cause?: string
  headerText?: string
  descriptionText?: string
  severityLevel?: string
  activePeriodStart?: number
  activePeriodEnd?: number
  informedEntities?: InformedEntity[]
  url?: string
  lastSeen: string
}
