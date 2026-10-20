.pragma library

// Open-Meteo request building and normalisation for the weather views.
// The cached response keeps the legacy `current_weather` block and the
// `weathercode` daily key, which the bar widget, calendar and dark mode read.

var detailKinds = ["wind", "uv", "humidity", "feelsLike", "sun", "airQuality", "pressure", "visibility", "precipitation", "moon"];

var windUnits = ["kmh", "ms", "mph", "kn"];

function forecastUrl(latitude, longitude) {
  var current = ["temperature_2m", "relative_humidity_2m", "apparent_temperature", "is_day", "precipitation", "weather_code", "cloud_cover", "surface_pressure", "wind_speed_10m", "wind_direction_10m", "wind_gusts_10m", "uv_index", "visibility", "dew_point_2m"];
  var hourly = ["temperature_2m", "weather_code", "precipitation_probability", "is_day"];
  var daily = ["weathercode", "temperature_2m_max", "temperature_2m_min", "sunrise", "sunset", "uv_index_max", "precipitation_probability_max", "precipitation_sum"];
  return "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + "&current_weather=true&current=" + current.join(",") + "&hourly=" + hourly.join(",") + "&daily=" + daily.join(",") + "&forecast_days=7&timezone=auto";
}

function airQualityUrl(latitude, longitude) {
  return "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=" + latitude + "&longitude=" + longitude + "&current=european_aqi,us_aqi,pm2_5,pm10&timezone=auto";
}

function _number(value) {
  return typeof value === "number" && isFinite(value) ? value : null;
}

function _first() {
  for (var i = 0; i < arguments.length; i++) {
    var value = _number(arguments[i]);
    if (value !== null)
      return value;
  }
  return null;
}

// Current conditions. Older caches only have `current_weather`, so every field may be null.
function current(weather) {
  if (!weather || !weather.current_weather)
    return null;
  var legacy = weather.current_weather;
  var now = weather.current || {};
  var isDay = now.is_day !== undefined ? now.is_day : legacy.is_day;
  return {
    "temperature": _first(now.temperature_2m, legacy.temperature),
    "feelsLike": _first(now.apparent_temperature),
    "code": _first(now.weather_code, legacy.weathercode) || 0,
    "isDay": isDay === undefined ? true : !!isDay,
    "humidity": _first(now.relative_humidity_2m, now.relativehumidity_2m),
    "windSpeed": _first(now.wind_speed_10m, legacy.windspeed),
    "windDirection": _first(now.wind_direction_10m, legacy.winddirection),
    "windGusts": _first(now.wind_gusts_10m),
    "pressure": _first(now.surface_pressure),
    "uv": _first(now.uv_index),
    "cloudCover": _first(now.cloud_cover),
    "visibility": _first(now.visibility),
    "dewPoint": _first(now.dew_point_2m),
    "precipitation": _first(now.precipitation),
    "time": now.time || legacy.time || ""
  };
}

// Index of the hour containing `isoTime` ("2026-10-19T14:15" matches "2026-10-19T14:00").
function _hourIndex(times, isoTime) {
  if (!times || times.length === 0)
    return -1;
  var hour = (isoTime || "").slice(0, 13);
  for (var i = 0; i < times.length; i++) {
    if (times[i].slice(0, 13) === hour)
      return i;
  }
  return times[0] > isoTime ? 0 : -1;
}

function hourly(weather, count) {
  var data = weather && weather.hourly;
  var now = current(weather);
  if (!data || !data.time || !now)
    return [];
  var start = _hourIndex(data.time, now.time);
  if (start < 0)
    return [];
  var result = [];
  for (var i = start; i < data.time.length && result.length < count; i++) {
    result.push({
                  "time": data.time[i],
                  "temperature": _number(data.temperature_2m ? data.temperature_2m[i] : null),
                  "code": data.weather_code ? data.weather_code[i] : 0,
                  "isDay": data.is_day ? !!data.is_day[i] : true,
                  "precipitationProbability": _number(data.precipitation_probability ? data.precipitation_probability[i] : null)
                });
  }
  return result;
}

function daily(weather, count) {
  var data = weather && weather.daily;
  if (!data || !data.time)
    return [];
  var result = [];
  var codes = data.weathercode || data.weather_code || [];
  for (var i = 0; i < data.time.length && i < count; i++) {
    result.push({
                  "date": data.time[i],
                  "max": _number(data.temperature_2m_max[i]),
                  "min": _number(data.temperature_2m_min[i]),
                  "code": codes[i] || 0,
                  "sunrise": data.sunrise ? data.sunrise[i] : "",
                  "sunset": data.sunset ? data.sunset[i] : "",
                  "uvMax": _number(data.uv_index_max ? data.uv_index_max[i] : null),
                  "precipitationProbability": _number(data.precipitation_probability_max ? data.precipitation_probability_max[i] : null),
                  "precipitationSum": _number(data.precipitation_sum ? data.precipitation_sum[i] : null)
                });
  }
  return result;
}

function airQuality(response) {
  var now = response && response.current;
  if (!now)
    return null;
  return {
    "europeanAqi": _number(now.european_aqi),
    "usAqi": _number(now.us_aqi),
    "pm25": _number(now.pm2_5),
    "pm10": _number(now.pm10)
  };
}

function temperature(celsius, fahrenheit) {
  if (_number(celsius) === null)
    return null;
  return Math.round(fahrenheit ? 32 + celsius * 1.8 : celsius);
}

function temperatureText(celsius, fahrenheit, withUnit) {
  var value = temperature(celsius, fahrenheit);
  if (value === null)
    return "--";
  return value + "°" + (withUnit ? (fahrenheit ? "F" : "C") : "");
}

// Open-Meteo reports wind in km/h.
function windSpeed(kmh, unit) {
  if (_number(kmh) === null)
    return null;
  if (unit === "ms")
    return Math.round(kmh / 3.6);
  if (unit === "mph")
    return Math.round(kmh / 1.609344);
  if (unit === "kn")
    return Math.round(kmh / 1.852);
  return Math.round(kmh);
}

function windUnitLabel(unit) {
  return {
    "ms": "m/s",
    "mph": "mph",
    "kn": "kn"
  }[unit] || "km/h";
}

function visibilityText(meters, imperial) {
  if (_number(meters) === null)
    return "--";
  if (imperial)
    return (Math.round(meters / 1609.344 * 10) / 10) + " mi";
  return meters >= 10000 ? Math.round(meters / 1000) + " km" : (Math.round(meters / 100) / 10) + " km";
}

// 16-point compass key, e.g. "N", "NNE".
function compass(degrees) {
  if (_number(degrees) === null)
    return "";
  var points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
  var normalized = ((degrees % 360) + 360) % 360;
  return points[Math.round(normalized / 22.5) % 16];
}

function uvLevel(uv) {
  if (_number(uv) === null)
    return "";
  if (uv < 3)
    return "low";
  if (uv < 6)
    return "moderate";
  if (uv < 8)
    return "high";
  if (uv < 11)
    return "very-high";
  return "extreme";
}

// European AQI bands.
function aqiLevel(aqi) {
  if (_number(aqi) === null)
    return "";
  if (aqi <= 20)
    return "good";
  if (aqi <= 40)
    return "fair";
  if (aqi <= 60)
    return "moderate";
  if (aqi <= 80)
    return "poor";
  if (aqi <= 100)
    return "very-poor";
  return "extremely-poor";
}

function clamp01(value) {
  return Math.max(0, Math.min(1, value));
}

// Gauge fill for each detail, 0..1.
function gaugeFraction(kind, value) {
  if (_number(value) === null)
    return 0;
  if (kind === "uv")
    return clamp01(value / 11);
  if (kind === "humidity" || kind === "precipitation")
    return clamp01(value / 100);
  if (kind === "pressure")
    return clamp01((value - 960) / 80);
  if (kind === "airQuality")
    return clamp01(value / 100);
  return 0;
}

// Sun position between sunrise and sunset: progress 0..1 and whether the sun is up.
function sunProgress(nowMs, sunriseIso, sunsetIso) {
  var rise = Date.parse(sunriseIso);
  var set = Date.parse(sunsetIso);
  if (!isFinite(rise) || !isFinite(set) || set <= rise)
    return {
      "progress": 0,
      "up": false
    };
  return {
    "progress": clamp01((nowMs - rise) / (set - rise)),
    "up": nowMs >= rise && nowMs <= set
  };
}

// Moon age as a fraction of the synodic month (0 new, 0.5 full) and its illumination.
function moonPhase(dateMs) {
  var synodic = 29.530588853;
  var knownNew = Date.UTC(2000, 0, 6, 18, 14);
  var days = (dateMs - knownNew) / 86400000;
  var age = ((days % synodic) + synodic) % synodic;
  var phase = age / synodic;
  var keys = ["new", "waxing-crescent", "first-quarter", "waxing-gibbous", "full", "waning-gibbous", "last-quarter", "waning-crescent"];
  return {
    "phase": phase,
    "illumination": Math.round((1 - Math.cos(phase * 2 * Math.PI)) / 2 * 100),
    "key": keys[Math.round(phase * 8) % 8]
  };
}

// Day range bar placed on the scale of the whole forecast.
function rangeBar(min, max, scaleMin, scaleMax) {
  var span = scaleMax - scaleMin;
  if (!(span > 0))
    return {
      "start": 0,
      "end": 1
    };
  return {
    "start": clamp01((min - scaleMin) / span),
    "end": clamp01((max - scaleMin) / span)
  };
}

function bounds(values) {
  var min = Infinity;
  var max = -Infinity;
  for (var i = 0; i < values.length; i++) {
    if (_number(values[i]) === null)
      continue;
    min = Math.min(min, values[i]);
    max = Math.max(max, values[i]);
  }
  if (min === Infinity)
    return {
      "min": 0,
      "max": 0
    };
  return {
    "min": min,
    "max": max
  };
}

// Evenly spaced chart points, highest value at `top`, lowest at `bottom`.
function chartPoints(values, width, top, bottom) {
  var range = bounds(values);
  var span = range.max - range.min;
  var step = values.length > 0 ? width / values.length : 0;
  var points = [];
  for (var i = 0; i < values.length; i++) {
    var ratio = span > 0 ? (values[i] - range.min) / span : 0.5;
    points.push({
                  "x": step * (i + 0.5),
                  "y": bottom - ratio * (bottom - top)
                });
  }
  return points;
}

// Saved detail list merged with the known kinds: keeps saved order and enabled
// flags, drops unknown ids and appends kinds added later as enabled.
function detailEntries(saved) {
  var result = [];
  var seen = {};
  for (var i = 0; saved && i < saved.length; i++) {
    var entry = saved[i];
    if (!entry || detailKinds.indexOf(entry.id) < 0 || seen[entry.id])
      continue;
    seen[entry.id] = true;
    result.push({
                  "id": entry.id,
                  "enabled": entry.enabled !== false
                });
  }
  for (var k = 0; k < detailKinds.length; k++) {
    if (!seen[detailKinds[k]])
      result.push({
                    "id": detailKinds[k],
                    "enabled": true
                  });
  }
  return result;
}

function enabledDetails(saved) {
  return detailEntries(saved).filter(function (entry) {
    return entry.enabled;
  }).map(function (entry) {
    return entry.id;
  });
}

function movedDetail(saved, from, to) {
  var entries = detailEntries(saved);
  if (from < 0 || to < 0 || from >= entries.length || to >= entries.length)
    return entries;
  var item = entries.splice(from, 1)[0];
  entries.splice(to, 0, item);
  return entries;
}

function toggledDetail(saved, index, enabled) {
  var entries = detailEntries(saved);
  if (index >= 0 && index < entries.length)
    entries[index].enabled = enabled;
  return entries;
}

// Tabler icon for a WMO weather code.
function symbol(code, isDay) {
  if (code === 0)
    return isDay ? "weather-sun" : "weather-moon";
  if (code === 1 || code === 2)
    return isDay ? "weather-cloud-sun" : "weather-moon-stars";
  if (code === 3)
    return "weather-cloud";
  if (code >= 45 && code <= 48)
    return "weather-cloud-haze";
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
    return "weather-cloud-rain";
  if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86))
    return "weather-cloud-snow";
  if (code >= 95 && code <= 99)
    return "weather-cloud-lightning";
  return "weather-cloud";
}

// Content of one detail tile. `context` holds { current, today, tomorrow, air,
// fahrenheit, windUnit, nowMs, formatTime(iso) }. Labels and captions are translation keys.
// visual: "gauge" (vertical pill), "cookie" (shape with icon or value), "sun" (arc), "moon" (disc).
function detail(kind, context) {
  var now = context.current || {};
  var today = context.today || {};
  var air = context.air || {};
  var f = !!context.fahrenheit;
  var tile = {
    "kind": kind,
    "icon": "",
    "label": "weather.details." + kind,
    "value": "--",
    "caption": {
      "key": "",
      "args": {}
    },
    "visual": "cookie",
    "fraction": 0,
    "rotation": 0,
    "valueIsKey": false
  };
  if (kind === "wind") {
    var speed = windSpeed(now.windSpeed, context.windUnit);
    tile.icon = "navigation";
    tile.value = speed === null ? "--" : speed + " " + windUnitLabel(context.windUnit);
    tile.rotation = _number(now.windDirection) === null ? 0 : (now.windDirection + 180) % 360;
    tile.caption = {
      "key": "weather.details.wind-caption",
      "args": {
        "gusts": _number(now.windGusts) === null ? "--" : windSpeed(now.windGusts, context.windUnit),
        "direction": compass(now.windDirection) || "--"
      }
    };
  } else if (kind === "uv") {
    tile.icon = "uv-index";
    tile.value = _number(now.uv) === null ? "--" : String(Math.round(now.uv));
    tile.fraction = gaugeFraction("uv", now.uv);
    tile.caption.key = _number(now.uv) === null ? "" : "weather.uv." + uvLevel(now.uv);
  } else if (kind === "humidity") {
    tile.icon = "droplet";
    tile.visual = "gauge";
    tile.value = _number(now.humidity) === null ? "--" : Math.round(now.humidity) + "%";
    tile.fraction = gaugeFraction("humidity", now.humidity);
    tile.caption = {
      "key": "weather.details.dew-point",
      "args": {
        "value": temperatureText(now.dewPoint, f, false)
      }
    };
  } else if (kind === "feelsLike") {
    tile.icon = "temperature";
    tile.visual = "gauge";
    tile.value = temperatureText(now.feelsLike, f, false);
    tile.fraction = _number(now.feelsLike) === null ? 0 : clamp01((now.feelsLike + 20) / 60);
    tile.caption = {
      "key": "weather.details.actual",
      "args": {
        "value": temperatureText(now.temperature, f, false)
      }
    };
  } else if (kind === "sun") {
    // Sun up: next sunset. Before sunrise: today's sunrise. After sunset: tomorrow's.
    var sun = sunProgress(context.nowMs, today.sunrise, today.sunset);
    var tomorrow = context.tomorrow || {};
    var nextRise = context.nowMs < Date.parse(today.sunrise) ? today.sunrise : (tomorrow.sunrise || today.sunrise);
    tile.icon = sun.up ? "sunset" : "sunrise";
    tile.visual = "sun";
    tile.fraction = sun.progress;
    tile.label = sun.up ? "weather.details.sunset" : "weather.details.sunrise";
    if (today.sunrise) {
      tile.value = context.formatTime(sun.up ? today.sunset : nextRise);
      tile.caption = {
        "key": sun.up ? "weather.details.sunrise-caption" : "weather.details.sunset-caption",
        "args": {
          "time": context.formatTime(sun.up ? today.sunrise : today.sunset)
        }
      };
    }
  } else if (kind === "airQuality") {
    tile.icon = "leaf";
    tile.visual = "gauge";
    tile.value = _number(air.europeanAqi) === null ? "--" : String(Math.round(air.europeanAqi));
    tile.fraction = gaugeFraction("airQuality", air.europeanAqi);
    tile.caption.key = _number(air.europeanAqi) === null ? "" : "weather.aqi." + aqiLevel(air.europeanAqi);
  } else if (kind === "pressure") {
    tile.icon = "gauge";
    tile.visual = "gauge";
    tile.value = _number(now.pressure) === null ? "--" : Math.round(now.pressure) + " hPa";
    tile.fraction = gaugeFraction("pressure", now.pressure);
    if (_number(now.pressure) !== null)
      tile.caption.key = now.pressure < 1000 ? "weather.details.pressure-low" : (now.pressure > 1020 ? "weather.details.pressure-high" : "weather.details.pressure-normal");
  } else if (kind === "visibility") {
    tile.icon = "eye";
    tile.value = visibilityText(now.visibility, f);
    tile.caption = {
      "key": _number(now.cloudCover) === null ? "" : "weather.details.cloud-cover",
      "args": {
        "value": Math.round(now.cloudCover || 0)
      }
    };
  } else if (kind === "precipitation") {
    tile.icon = "umbrella";
    tile.visual = "gauge";
    tile.value = _number(today.precipitationProbability) === null ? "--" : Math.round(today.precipitationProbability) + "%";
    tile.fraction = gaugeFraction("precipitation", today.precipitationProbability);
    tile.caption = {
      "key": _number(today.precipitationSum) === null ? "" : "weather.details.precipitation-sum",
      "args": {
        "value": Math.round((today.precipitationSum || 0) * 10) / 10
      }
    };
  } else if (kind === "moon") {
    var moon = moonPhase(context.nowMs);
    tile.icon = "moon";
    tile.visual = "moon";
    tile.fraction = moon.phase;
    tile.value = "weather.moon." + moon.key;
    tile.valueIsKey = true;
    tile.caption = {
      "key": "weather.details.illumination",
      "args": {
        "value": moon.illumination
      }
    };
  }
  return tile;
}
