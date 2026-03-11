interface RouteInfo {
  shortName: string
  color: string
  textColor: string
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
    const color = cols[7]?.trim()
    const textColor = cols[8]?.trim()
    if (routeId && shortName) {
      cache.set(routeId, {
        shortName,
        color: color ? `#${color}` : '#3b82f6',
        textColor: textColor ? `#${textColor}` : '#ffffff',
      })
    }
  }

  return cache
}
