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
}
