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

var views = ["current", "hourly", "daily"];
var viewLabels = {
  current: "panels.desktop-widgets.weather-view-current",
  hourly: "panels.desktop-widgets.weather-view-hourly",
  daily: "panels.desktop-widgets.weather-view-daily"
};

function view(value) {
  return views.indexOf(value) >= 0 ? value : "current";
}

// Base size before widgetScale. A zero height follows the selected view's content.
function desktopSize(kind, compact) {
  switch (kind) {
  case "hourly":
    return { width: 400, height: 0 };
  case "daily":
    return { width: compact ? 320 : 300, height: 0 };
  case "detail":
    return { width: 240, height: 120 };
  default:
    return { width: 240, height: 0 };
  }
}

function hourlyWidgetWidth(count, columnWidth, padding, minimumWidth) {
  return Math.ceil(Math.max(minimumWidth, Math.max(0, count) * columnWidth + padding * 2));
}

function hourlyColumnWidth(width, count) {
  return Math.max(0, width) / Math.max(1, count);
}

// Consolidate saved weather widgets without changing their instance data or order.
function migrateDesktopWidgets(monitors) {
  if (!Array.isArray(monitors))
    return monitors;
  const legacyViews = { WeatherHourly: "hourly", WeatherDaily: "daily", WeatherDetail: "detail" };
  let changed = false;
  const result = monitors.map(monitor => {
    if (!monitor || !Array.isArray(monitor.widgets))
      return monitor;
    let monitorChanged = false;
    const widgets = monitor.widgets.map(widget => {
      if (!widget || !Object.prototype.hasOwnProperty.call(legacyViews, widget.id))
        return widget;
      monitorChanged = true;
      return Object.assign({}, widget, { id: "Weather", view: legacyViews[widget.id] });
    });
    if (!monitorChanged)
      return monitor;
    changed = true;
    return Object.assign({}, monitor, { widgets: widgets });
  });
  return changed ? result : monitors;
}

// Detail tiles have their own widget and selector, separate from forecasts.
function splitDetailWidgets(monitors) {
  if (!Array.isArray(monitors))
    return monitors;
  let changed = false;
  const result = monitors.map(monitor => {
    if (!monitor || !Array.isArray(monitor.widgets))
      return monitor;
    let monitorChanged = false;
    const widgets = monitor.widgets.map(widget => {
      if (!widget || widget.id !== "Weather" || widget.view !== "detail")
        return widget;
      monitorChanged = true;
      const detail = Object.assign({}, widget, { id: "WeatherDetails" });
      delete detail.view;
      return detail;
    });
    if (!monitorChanged)
      return monitor;
    changed = true;
    return Object.assign({}, monitor, { widgets: widgets });
  });
  return changed ? result : monitors;
}

// Rain chance label: always shown so the forecast has no holes; a low chance
// is dimmed instead of hidden.
function precipitationLabel(probability) {
  if (probability === null || probability === undefined || !isFinite(probability))
    return { text: "--", dim: true };
  var value = Math.round(probability);
  return { text: value + "%", dim: value < 10 };
}
