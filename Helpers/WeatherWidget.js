.pragma library

function conditionKey(code) {
  if (code === 0) return "weather.clear-sky";
  if (code === 1) return "weather.mainly-clear";
  if (code === 2) return "weather.partly-cloudy";
  if (code === 3) return "weather.overcast";
  if (code === 45 || code === 48) return "weather.fog";
  if (code >= 51 && code <= 67) return "weather.drizzle";
  if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return "weather.snow";
  if (code >= 80 && code <= 82) return "weather.rain-showers";
  if (code >= 95 && code <= 99) return "weather.thunderstorm";
  return "weather.unknown";
}

function summary(weather, enabled, fahrenheit, locationConfigured) {
  var current = weather && weather.current_weather;
  var ready = enabled && current && typeof current.temperature === "number" && isFinite(current.temperature);
  return {
    visible: enabled,
    ready: !!ready,
    text: ready ? Math.round(fahrenheit ? 32 + current.temperature * 1.8 : current.temperature) + "°" + (fahrenheit ? "F" : "C") : "--",
    code: ready ? current.weathercode : 0,
    conditionKey: ready ? conditionKey(current.weathercode) : "",
    statusKey: locationConfigured ? "common.weather-loading" : "common.weather-no-location",
    fallbackIcon: locationConfigured ? "weather-cloud-off" : "map-pin-off"
  };
}

// Base size of the weather desktop widgets before widgetScale, on the same
// scale as the other desktop widgets (system monitor 240x120, media player 400).
// A height of 0 means the widget follows its content.
function desktopSize(kind, compact) {
  switch (kind) {
  case "WeatherHourly":
    return { width: 400, height: 0 };
  case "WeatherDaily":
    return { width: compact ? 320 : 300, height: 0 };
  case "WeatherDetail":
    return { width: 240, height: 120 };
  default:
    return { width: 240, height: 0 };
  }
}

// Rain chance label: always shown so the forecast has no holes; a low chance
// is dimmed instead of hidden.
function precipitationLabel(probability) {
  if (probability === null || probability === undefined || !isFinite(probability))
    return { text: "--", dim: true };
  var value = Math.round(probability);
  return { text: value + "%", dim: value < 10 };
}
