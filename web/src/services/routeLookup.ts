export interface RouteInfo {
  shortName: string
  color: string
  textColor: string
  routeType: number // GTFS route_type: 0=tram/LRT, 1=subway, 2=rail, 3=bus, 4=ferry
}

let cache: Map<string, RouteInfo> | null = null

export async function getRouteLookup(): Promise<Map<string, RouteInfo>> {
  if (cache) return cache

  const res = await fetch('/routes.csv')
  const text = await res.text()
  const lines = text.trim().split('\n')

  cache = new Map()
  for (let i = 1; i < lines.length; i++) {
    const cols = lines[i].split(',')
    const routeId = cols[0]?.trim()
    const shortName = cols[2]?.trim()
    const routeType = parseInt(cols[5]?.trim() ?? '3', 10)
    const color = cols[7]?.trim()
    const textColor = cols[8]?.trim()
    if (routeId && shortName) {
      cache.set(routeId, {
        shortName,
        routeType: isNaN(routeType) ? 3 : routeType,
        color: color ? `#${color}` : '#3b82f6',
        textColor: textColor ? `#${textColor}` : '#ffffff',
      })
    }
  }

  return cache
}
