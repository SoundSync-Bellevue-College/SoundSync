// Shape returned by the Go backend, which proxies weather.gov (NWS).
export interface WeatherData {
  temp: number          // °F
  description: string   // shortForecast, e.g. "Partly Cloudy"
  detailedForecast: string
  windSpeed: string     // e.g. "12 mph"
  windDirection: string // e.g. "SW"
  iconUrl: string       // NWS icon URL
  isDaytime: boolean
  cityName: string
  timestamp: string
}

export interface HourlyPeriod {
  number: number
  startTime: string     // ISO-8601
  temperature: number   // °F
  windSpeed: string
  windDirection: string
  shortForecast: string
  iconUrl: string
  isDaytime: boolean
}

export interface HourlyForecast {
  cityName: string
  periods: HourlyPeriod[]
}
