import QtQuick
import QtTest
import "../Helpers/WeatherScene.js" as WeatherScene

TestCase {
  name: "WeatherScene"

  function test_type_data() {
    return [
          { tag: "clear", code: 0, expected: "clear" },
          { tag: "mainly clear", code: 1, expected: "partly" },
          { tag: "overcast", code: 3, expected: "overcast" },
          { tag: "fog", code: 45, expected: "overcast" },
          { tag: "drizzle", code: 53, expected: "rain" },
          { tag: "showers", code: 81, expected: "rain" },
          { tag: "snow", code: 73, expected: "snow" },
          { tag: "snow showers", code: 86, expected: "snow" },
          { tag: "thunderstorm", code: 95, expected: "storm" }
        ];
  }

  function test_type(data) {
    compare(WeatherScene.type(data.code), data.expected);
  }

  function test_windy() {
    verify(WeatherScene.windy("clear", 9, 0));
    verify(WeatherScene.windy("overcast", 2, 12));
    verify(!WeatherScene.windy("rain", 20, 20), "rain keeps its own scene");
    verify(!WeatherScene.windy("clear", 3, NaN));
  }

  function test_visualType() {
    compare(WeatherScene.visualType("clear", true), "overcast");
    compare(WeatherScene.visualType("partly", false), "partly");
    compare(WeatherScene.cloudBandCount("clear"), 0);
    compare(WeatherScene.cloudBandCount("partly"), 2);
    compare(WeatherScene.cloudBandCount("storm"), 3);
  }

  function test_paletteDayAndNight() {
    compare(WeatherScene.palette("clear", false).top, "#7fc5e5");
    compare(WeatherScene.palette("partly", true).top, WeatherScene.palette("clear", true).top);
    compare(WeatherScene.palette("unknown", false).top, "#86a0b5");
  }

  function test_onSkyColorIsReadable() {
    compare(WeatherScene.onSkyColor(WeatherScene.palette("clear", false)), "#1b2430");
    compare(WeatherScene.onSkyColor(WeatherScene.palette("storm", true)), "#f4f6fb");
    compare(WeatherScene.onSkyColor(WeatherScene.palette("rain", true)), "#f4f6fb");
  }
}
