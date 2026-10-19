import QtQuick
import QtTest
import "../Helpers/WeatherWidget.js" as WeatherWidget

TestCase {
  name: "WeatherWidget"

  function test_temperature_data() {
    return [
          {
            tag: "celsius",
            temperature: 23.6,
            fahrenheit: false,
            expected: "24°C"
          },
          {
            tag: "fahrenheit",
            temperature: 23.6,
            fahrenheit: true,
            expected: "74°F"
          },
          {
            tag: "freezing celsius",
            temperature: 0,
            fahrenheit: false,
            expected: "0°C"
          },
          {
            tag: "freezing fahrenheit",
            temperature: 0,
            fahrenheit: true,
            expected: "32°F"
          },
          {
            tag: "negative",
            temperature: -12.4,
            fahrenheit: false,
            expected: "-12°C"
          },
          {
            tag: "below zero fahrenheit",
            temperature: -20,
            fahrenheit: true,
            expected: "-4°F"
          }
        ];
  }

  function test_temperature(data) {
    var weather = {
      current_weather: {
        temperature: data.temperature,
        weathercode: 3
      }
    };
    var summary = WeatherWidget.summary(weather, true, data.fahrenheit, true);
    verify(summary.visible);
    verify(summary.ready);
    compare(summary.text, data.expected);
    compare(summary.code, 3);
    compare(summary.conditionKey, "weather.overcast");
    compare(weather.current_weather.temperature, data.temperature);
  }

  function test_unavailableWeather_data() {
    return [
          {
            tag: "loading",
            weather: null
          },
          {
            tag: "missing current data",
            weather: {}
          },
          {
            tag: "null temperature",
            weather: {
              current_weather: {
                temperature: null
              }
            }
          },
          {
            tag: "NaN temperature",
            weather: {
              current_weather: {
                temperature: NaN
              }
            }
          },
          {
            tag: "infinite temperature",
            weather: {
              current_weather: {
                temperature: Infinity
              }
            }
          }
        ];
  }

  function test_unavailableWeather(data) {
    var summary = WeatherWidget.summary(data.weather, true, false, true);
    verify(summary.visible);
    verify(!summary.ready);
    compare(summary.text, "--");
    compare(summary.statusKey, "common.weather-loading");
    compare(summary.fallbackIcon, "weather-cloud-off");
    compare(summary.conditionKey, "");
  }

  function test_missingLocationAndDisabledWeather() {
    var summary = WeatherWidget.summary(null, true, false, false);
    compare(summary.statusKey, "common.weather-no-location");
    compare(summary.fallbackIcon, "map-pin-off");
    summary = WeatherWidget.summary({
                                      current_weather: {
                                        temperature: 25
                                      }
                                    }, false, false, true);
    verify(!summary.visible);
    verify(!summary.ready);
    compare(summary.text, "--");
  }

  function test_conditions_data() {
    return [
          {
            tag: "clear",
            code: 0,
            key: "clear-sky"
          },
          {
            tag: "mainly clear",
            code: 1,
            key: "mainly-clear"
          },
          {
            tag: "partly cloudy",
            code: 2,
            key: "partly-cloudy"
          },
          {
            tag: "cloudy",
            code: 3,
            key: "overcast"
          },
          {
            tag: "fog",
            code: 45,
            key: "fog"
          },
          {
            tag: "freezing fog",
            code: 48,
            key: "fog"
          },
          {
            tag: "drizzle",
            code: 51,
            key: "drizzle"
          },
          {
            tag: "snow",
            code: 71,
            key: "snow"
          },
          {
            tag: "snow shower",
            code: 85,
            key: "snow"
          },
          {
            tag: "rain shower",
            code: 80,
            key: "rain-showers"
          },
          {
            tag: "thunderstorm",
            code: 95,
            key: "thunderstorm"
          },
          {
            tag: "unknown",
            code: -1,
            key: "unknown"
          }
        ];
  }

  function test_conditions(data) {
    compare(WeatherWidget.conditionKey(data.code), "weather." + data.key);
  }

  function test_desktopSize_data() {
    return [
          {
            tag: "current",
            kind: "current",
            compact: false,
            width: 240,
            height: 0
          },
          {
            tag: "hourly",
            kind: "hourly",
            compact: false,
            width: 400,
            height: 0
          },
          {
            tag: "daily rows",
            kind: "daily",
            compact: false,
            width: 300,
            height: 0
          },
          {
            tag: "daily strip",
            kind: "daily",
            compact: true,
            width: 320,
            height: 0
          },
          {
            tag: "detail",
            kind: "detail",
            compact: false,
            width: 240,
            height: 120
          }
        ];
  }

  function test_desktopSize(data) {
    const size = WeatherWidget.desktopSize(data.kind, data.compact);
    compare(size.width, data.width);
    compare(size.height, data.height);
  }

  function test_views() {
    compare(WeatherWidget.views, ["current", "hourly", "daily", "detail"]);
    for (const selected of WeatherWidget.views)
      compare(WeatherWidget.view(selected), selected);
    for (const invalid of [undefined, null, "", "unknown", "toString"])
      compare(WeatherWidget.view(invalid), "current");
    compare(WeatherWidget.desktopSize("unknown", true), {
              width: 240,
              height: 0
            });
  }

  function test_migratesAllLegacyWeatherViews_data() {
    return [
          {
            tag: "hourly",
            id: "WeatherHourly",
            view: "hourly",
            settings: {
              hours: 24,
              showPrecipitation: false
            }
          },
          {
            tag: "daily",
            id: "WeatherDaily",
            view: "daily",
            settings: {
              days: 5,
              compact: true
            }
          },
          {
            tag: "detail",
            id: "WeatherDetail",
            view: "detail",
            settings: {
              detail: "moon"
            }
          }
        ];
  }

  function test_migratesAllLegacyWeatherViews(data) {
    const widget = Object.assign({
                                   id: data.id,
                                   x: 31,
                                   y: 92,
                                   scale: 1.4,
                                   showBackground: false,
                                   roundedCorners: false
                                 }, data.settings);
    const untouched = {
      id: "Clock",
      x: 1
    };
    const current = {
      id: "Weather",
      forecastDays: 3
    };
    const monitors = [
            {
              name: "DP-1",
              extra: "preserved",
              widgets: [untouched, widget, current]
            },
            {
              name: "DP-2",
              widgets: [
                {
                  id: "plugin:weather"
                }
              ]
            }
          ];
    const snapshot = JSON.stringify(monitors);
    const result = WeatherWidget.migrateDesktopWidgets(monitors);
    compare(result[0].widgets[1], Object.assign({}, widget, {
                                                  id: "Weather",
                                                  view: data.view
                                                }));
    compare(result[0].name, "DP-1");
    compare(result[0].extra, "preserved");
    verify(result[0].widgets[0] === untouched);
    verify(result[0].widgets[2] === current);
    verify(result[1] === monitors[1]);
    compare(JSON.stringify(monitors), snapshot);
    verify(WeatherWidget.migrateDesktopWidgets(result) === result);
  }

  function test_migrationPreservesEmptyAndUnrelatedLayouts() {
    for (const input of [undefined, null, [], [
                           {
                             name: "empty"
                           }
                         ], [
                           {
                             widgets: []
                           }
                         ], [
                           {
                             widgets: [null,
                               {
                                 id: "Weather",
                                 view: "detail",
                                 detail: "wind"
                               },
                               {
                                 id: "toString"
                               }
                             ]
                           }
                         ]])
      verify(WeatherWidget.migrateDesktopWidgets(input) === input);
  }

  function test_precipitationLabel_data() {
    return [
          {
            tag: "likely",
            value: 83.4,
            text: "83%",
            dim: false
          },
          {
            tag: "threshold",
            value: 10,
            text: "10%",
            dim: false
          },
          {
            tag: "low is shown dimmed",
            value: 4,
            text: "4%",
            dim: true
          },
          {
            tag: "zero",
            value: 0,
            text: "0%",
            dim: true
          },
          {
            tag: "missing",
            value: null,
            text: "--",
            dim: true
          },
          {
            tag: "undefined",
            value: undefined,
            text: "--",
            dim: true
          }
        ];
  }

  function test_precipitationLabel(data) {
    const label = WeatherWidget.precipitationLabel(data.value);
    compare(label.text, data.text);
    compare(label.dim, data.dim);
  }
}
