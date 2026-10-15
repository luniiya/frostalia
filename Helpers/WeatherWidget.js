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
