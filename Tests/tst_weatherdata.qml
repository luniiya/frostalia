import QtQuick
import QtTest
import "../Helpers/WeatherData.js" as WeatherData

TestCase {
  name: "WeatherData"

  function sample() {
    return {
      "current_weather": {
        "temperature": 11.2,
        "weathercode": 3,
        "is_day": 1,
        "time": "2026-10-19T14:15"
      },
      "current": {
        "time": "2026-10-19T14:15",
        "temperature_2m": 11.4,
        "apparent_temperature": 9.1,
        "relative_humidity_2m": 72,
        "is_day": 1,
        "weather_code": 61,
        "wind_speed_10m": 18,
        "wind_direction_10m": 225,
        "wind_gusts_10m": 34,
        "surface_pressure": 1012.3,
        "uv_index": 2.4,
        "visibility": 24140,
        "precipitation": 0.4
      },
      "hourly": {
        "time": ["2026-10-19T13:00", "2026-10-19T14:00", "2026-10-19T15:00", "2026-10-19T16:00"],
        "temperature_2m": [10, 11, 12, 9],
        "weather_code": [3, 61, 61, 2],
        "precipitation_probability": [20, 60, 70, 10],
        "is_day": [1, 1, 1, 0]
      },
      "daily": {
        "time": ["2026-10-19", "2026-10-20"],
        "weathercode": [61, 0],
        "temperature_2m_max": [13.4, 16],
        "temperature_2m_min": [6.1, 4],
        "sunrise": ["2026-10-19T08:10", "2026-10-20T08:12"],
        "sunset": ["2026-10-19T18:50", "2026-10-20T18:48"],
        "uv_index_max": [3.1, 4],
        "precipitation_probability_max": [80, 5],
        "precipitation_sum": [4.2, 0]
      }
    };
  }

  function test_forecastUrlKeepsLegacyFields() {
    const url = WeatherData.forecastUrl("48.85", "2.35");
    verify(url.indexOf("latitude=48.85&longitude=2.35") > 0);
    verify(url.indexOf("current_weather=true") > 0, "bar and calendar read current_weather");
    verify(url.indexOf("daily=weathercode,") > 0, "cards read daily.weathercode");
    verify(url.indexOf("sunrise") > 0 && url.indexOf("sunset") > 0, "dark mode reads sunrise/sunset");
    verify(url.indexOf("hourly=") > 0);
  }

  function test_currentPrefersDetailedBlock() {
    const now = WeatherData.current(sample());
    compare(now.temperature, 11.4);
    compare(now.feelsLike, 9.1);
    compare(now.code, 61);
    compare(now.humidity, 72);
    compare(now.windDirection, 225);
    compare(now.isDay, true);
  }

  function test_currentFallsBackToLegacyCache() {
    const now = WeatherData.current({
                                      "current_weather": {
                                        "temperature": 5,
                                        "weathercode": 0,
                                        "is_day": 0,
                                        "time": "2026-10-19T22:00"
                                      }
                                    });
    compare(now.temperature, 5);
    compare(now.code, 0);
    compare(now.isDay, false);
    compare(now.feelsLike, null);
    compare(WeatherData.current(null), null);
  }

  function test_hourlyStartsAtCurrentHour() {
    const hours = WeatherData.hourly(sample(), 2);
    compare(hours.length, 2);
    compare(hours[0].time, "2026-10-19T14:00");
    compare(hours[0].precipitationProbability, 60);
    compare(hours[1].temperature, 12);
    compare(WeatherData.hourly(sample(), 10).length, 3);
  }

  function test_hourlyEmptyWithoutData() {
    compare(WeatherData.hourly({
                                 "current_weather": {
                                   "time": "x"
                                 }
                               }, 4).length, 0);
  }

  function test_daily() {
    const days = WeatherData.daily(sample(), 7);
    compare(days.length, 2);
    compare(days[0].code, 61);
    compare(days[0].max, 13.4);
    compare(days[1].precipitationProbability, 5);
    compare(WeatherData.daily(sample(), 1).length, 1);
  }

  function test_airQuality() {
    const air = WeatherData.airQuality({
                                         "current": {
                                           "european_aqi": 32,
                                           "pm2_5": 7.5
                                         }
                                       });
    compare(air.europeanAqi, 32);
    compare(air.pm25, 7.5);
    compare(air.usAqi, null);
    compare(WeatherData.airQuality({}), null);
  }

  function test_temperatureText_data() {
    return [
          { tag: "celsius", c: 11.4, f: false, unit: false, expected: "11°" },
          { tag: "fahrenheit unit", c: 0, f: true, unit: true, expected: "32°F" },
          { tag: "missing", c: null, f: false, unit: true, expected: "--" }
        ];
  }

  function test_temperatureText(data) {
    compare(WeatherData.temperatureText(data.c, data.f, data.unit), data.expected);
  }

  function test_windSpeed_data() {
    return [
          { tag: "kmh", unit: "kmh", expected: 36 },
          { tag: "ms", unit: "ms", expected: 10 },
          { tag: "mph", unit: "mph", expected: 22 },
          { tag: "kn", unit: "kn", expected: 19 },
          { tag: "unknown falls back to kmh", unit: "x", expected: 36 }
        ];
  }

  function test_windSpeed(data) {
    compare(WeatherData.windSpeed(36, data.unit), data.expected);
  }

  function test_windUnitsHaveLabels() {
    compare(WeatherData.windUnits.map(WeatherData.windUnitLabel), ["km/h", "m/s", "mph", "kn"]);
  }

  function test_visibility() {
    compare(WeatherData.visibilityText(24140, false), "24 km");
    compare(WeatherData.visibilityText(2500, false), "2.5 km");
    compare(WeatherData.visibilityText(16093.44, true), "10 mi");
    compare(WeatherData.visibilityText(null, false), "--");
  }

  function test_compass_data() {
    return [
          { tag: "north", deg: 0, expected: "N" },
          { tag: "wraps", deg: 359, expected: "N" },
          { tag: "southwest", deg: 225, expected: "SW" },
          { tag: "east-northeast", deg: 70, expected: "ENE" },
          { tag: "negative", deg: -90, expected: "W" }
        ];
  }

  function test_compass(data) {
    compare(WeatherData.compass(data.deg), data.expected);
  }

  function test_levels() {
    compare(WeatherData.uvLevel(2.4), "low");
    compare(WeatherData.uvLevel(7), "high");
    compare(WeatherData.uvLevel(11), "extreme");
    compare(WeatherData.aqiLevel(15), "good");
    compare(WeatherData.aqiLevel(55), "moderate");
    compare(WeatherData.aqiLevel(140), "extremely-poor");
    compare(WeatherData.aqiLevel(null), "");
  }

  function test_gaugeFraction() {
    compare(WeatherData.gaugeFraction("humidity", 50), 0.5);
    compare(WeatherData.gaugeFraction("uv", 22), 1);
    compare(WeatherData.gaugeFraction("pressure", 1000), 0.5);
    compare(WeatherData.gaugeFraction("wind", 10), 0);
  }

  function test_sunProgress() {
    const rise = "2026-10-19T08:00";
    const set = "2026-10-19T18:00";
    const noon = Date.parse("2026-10-19T13:00");
    compare(WeatherData.sunProgress(noon, rise, set).progress, 0.5);
    verify(WeatherData.sunProgress(noon, rise, set).up);
    const night = WeatherData.sunProgress(Date.parse("2026-10-19T21:00"), rise, set);
    compare(night.progress, 1);
    verify(!night.up);
    compare(WeatherData.sunProgress(noon, "", set).up, false);
  }

  function test_moonPhase() {
    // 2026-10-26 is a full moon, 2026-10-10 a new moon.
    const full = WeatherData.moonPhase(Date.UTC(2026, 9, 26, 4, 0));
    compare(full.key, "full");
    verify(full.illumination > 95);
    const fresh = WeatherData.moonPhase(Date.UTC(2026, 9, 10, 16, 0));
    compare(fresh.key, "new");
    verify(fresh.illumination < 5);
  }

  function test_rangeBar() {
    const bar = WeatherData.rangeBar(5, 15, 0, 20);
    compare(bar.start, 0.25);
    compare(bar.end, 0.75);
    compare(WeatherData.rangeBar(3, 3, 3, 3).end, 1);
  }

  function test_chartPoints() {
    const points = WeatherData.chartPoints([10, 20, 15], 300, 0, 100);
    compare(points.length, 3);
    compare(points[0].x, 50);
    compare(points[0].y, 100);
    compare(points[1].y, 0);
    compare(points[2].y, 50);
    compare(WeatherData.chartPoints([4, 4], 100, 0, 100)[0].y, 50);
  }

  function test_detailEntriesMergesSaved() {
    const entries = WeatherData.detailEntries([
                                                {
                                                  "id": "moon",
                                                  "enabled": false
                                                },
                                                {
                                                  "id": "gone"
                                                },
                                                {
                                                  "id": "wind",
                                                  "enabled": true
                                                },
                                                {
                                                  "id": "moon"
                                                }
                                              ]);
    compare(entries.length, WeatherData.detailKinds.length);
    compare(entries[0].id, "moon");
    compare(entries[0].enabled, false);
    compare(entries[1].id, "wind");
    compare(entries[2].id, "uv");
    compare(entries[2].enabled, true);
  }

  function test_enabledDetails() {
    compare(WeatherData.enabledDetails([]).length, WeatherData.detailKinds.length);
    const toggled = WeatherData.toggledDetail([], 0, false);
    verify(WeatherData.enabledDetails(toggled).indexOf("wind") < 0);
  }

  function test_movedDetail() {
    const moved = WeatherData.movedDetail([], 0, 2);
    compare(moved[2].id, "wind");
    compare(moved[0].id, "uv");
    compare(WeatherData.movedDetail([], 0, 99)[0].id, "wind");
  }

  function test_symbol() {
    compare(WeatherData.symbol(0, true), "weather-sun");
    compare(WeatherData.symbol(0, false), "weather-moon");
    compare(WeatherData.symbol(81, true), "weather-cloud-rain");
    compare(WeatherData.symbol(86, true), "weather-cloud-snow");
    compare(WeatherData.symbol(96, false), "weather-cloud-lightning");
  }

  function detailContext(nowIso) {
    const data = sample();
    return {
      "current": WeatherData.current(data),
      "today": WeatherData.daily(data, 2)[0],
      "tomorrow": WeatherData.daily(data, 2)[1],
      "air": {
        "europeanAqi": 45
      },
      "fahrenheit": false,
      "windUnit": "kmh",
      "nowMs": Date.parse(nowIso),
      "formatTime": iso => iso.slice(11, 16)
    };
  }

  function test_detailEveryKindHasContent() {
    for (let i = 0; i < WeatherData.detailKinds.length; i++) {
      const tile = WeatherData.detail(WeatherData.detailKinds[i], detailContext("2026-10-19T14:15"));
      verify(tile.icon !== "", WeatherData.detailKinds[i]);
      verify(tile.value !== "--", WeatherData.detailKinds[i]);
      verify(["gauge", "cookie", "sun", "moon"].indexOf(tile.visual) >= 0);
    }
  }

  function test_detailWind() {
    const tile = WeatherData.detail("wind", detailContext("2026-10-19T14:15"));
    compare(tile.value, "18 km/h");
    compare(tile.rotation, 45);
    compare(tile.caption.args.gusts, 34);
    compare(tile.caption.args.direction, "SW");
  }

  function test_detailGauges() {
    const ctx = detailContext("2026-10-19T14:15");
    compare(WeatherData.detail("humidity", ctx).fraction, 0.72);
    compare(WeatherData.detail("humidity", ctx).caption.key, "weather.details.dew-point");
    compare(WeatherData.detail("airQuality", ctx).caption.key, "weather.aqi.moderate");
    compare(WeatherData.detail("pressure", ctx).caption.key, "weather.details.pressure-normal");
    compare(WeatherData.detail("uv", ctx).caption.key, "weather.uv.low");
    compare(WeatherData.detail("precipitation", ctx).value, "80%");
  }

  function test_detailSun_data() {
    return [
          { tag: "before sunrise", now: "2026-10-19T06:00", label: "weather.details.sunrise", value: "08:10" },
          { tag: "daytime", now: "2026-10-19T14:15", label: "weather.details.sunset", value: "18:50" },
          { tag: "after sunset shows tomorrow", now: "2026-10-19T21:00", label: "weather.details.sunrise", value: "08:12" }
        ];
  }

  function test_detailSun(data) {
    const tile = WeatherData.detail("sun", detailContext(data.now));
    compare(tile.label, data.label);
    compare(tile.value, data.value);
  }

  function test_detailMissingDataShowsDashes() {
    const tile = WeatherData.detail("airQuality", {
                                      "nowMs": 0,
                                      "formatTime": iso => iso
                                    });
    compare(tile.value, "--");
    compare(tile.caption.key, "");
    compare(WeatherData.detail("sun", {
                                 "nowMs": 0,
                                 "formatTime": iso => iso
                               }).value, "--");
  }

  function test_detailMoonValueIsKey() {
    const tile = WeatherData.detail("moon", detailContext("2026-10-26T04:00"));
    verify(tile.valueIsKey);
    compare(tile.value, "weather.moon.full");
  }
}
