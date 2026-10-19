"""Weather desktop widgets: registry entries, settings files and shared weather elements."""
import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
REGISTRY = (ROOT / "Services/UI/DesktopWidgetRegistry.qml").read_text()
EN = json.loads((ROOT / "Assets/Translations/en.json").read_text())
WEATHER_WIDGETS = ("Weather", "WeatherHourly", "WeatherDaily", "WeatherDetail")


def metadata(widget_id):
    block = re.search(r'"%s": \{(.*?)\}' % widget_id, REGISTRY.split("property var widgetMetadata")[1], re.S)
    return dict(re.findall(r'"(\w+)": ("[^"]*"|\w+)', block.group(1)))


class WeatherWidgetTests(unittest.TestCase):
    def test_registered_with_component_url_and_settings(self):
        for widget_id in WEATHER_WIDGETS:
            qml = "Desktop%s.qml" % widget_id
            self.assertIn('widgetsObj["%s"]' % widget_id, REGISTRY)
            self.assertIn('urlsObj["%s"] = _widgetsDir + "%s"' % (widget_id, qml), REGISTRY)
            self.assertTrue((ROOT / "Modules/DesktopWidgets/Widgets" / qml).exists(), qml)
            settings = re.search(r'"%s": "(WidgetSettings/[^"]+)"' % widget_id, REGISTRY)
            self.assertIsNotNone(settings, widget_id)
            self.assertTrue((ROOT / "Modules/Panels/Settings/DesktopWidgets" / settings.group(1)).exists())

    def test_widget_settings_have_defaults(self):
        # Every key a widget reads or a settings form writes needs a registry default.
        for widget_id in WEATHER_WIDGETS:
            defaults = metadata(widget_id)
            widget = (ROOT / ("Modules/DesktopWidgets/Widgets/Desktop%s.qml" % widget_id)).read_text()
            settings = (ROOT / ("Modules/Panels/Settings/DesktopWidgets/WidgetSettings/%sSettings.qml" % widget_id)).read_text()
            for key in re.findall(r'widgetSetting\("(\w+)"\)', widget) + re.findall(r'\.set\("(\w+)"', settings):
                self.assertIn(key, defaults, "%s.%s" % (widget_id, key))
            self.assertIn("WeatherBackgroundToggles", settings)

    def test_detail_default_is_a_known_kind(self):
        kinds = re.search(r"var detailKinds = \[(.*?)\];", (ROOT / "Helpers/WeatherData.js").read_text()).group(1)
        self.assertIn(metadata("WeatherDetail")["detail"], kinds)

    def test_core_widgets_have_display_names(self):
        names = EN["panels"]["desktop-widgets"]["names"]
        for widget_id in re.findall(r'widgetsObj\["(\w+)"\]', REGISTRY):
            self.assertIn(widget_id, names)

    def test_detail_kinds_are_translated(self):
        kinds = re.findall(r'"(\w+)"', re.search(r"var detailKinds = \[(.*?)\];", (ROOT / "Helpers/WeatherData.js").read_text()).group(1))
        for kind in kinds:
            self.assertIn(kind, EN["weather"]["details"])
        for group, keys in (("uv", ("low", "moderate", "high", "very-high", "extreme")),
                            ("aqi", ("good", "fair", "moderate", "poor", "very-poor", "extremely-poor")),
                            ("moon", ("new", "waxing-crescent", "first-quarter", "waxing-gibbous", "full",
                                      "waning-gibbous", "last-quarter", "waning-crescent"))):
            for key in keys:
                self.assertIn(key, EN["weather"][group])

    def test_weather_surfaces_cover_both_ui_styles(self):
        # Material and Caelestia get the same weather views; only the surface differs.
        surface = (ROOT / "Modules/Weather/WeatherSurface.qml").read_text()
        self.assertIn("Style.uiStyleTokens.weather", surface)
        self.assertIn("Style.radiusM", surface)
        for view in ("WeatherView.qml",):
            self.assertIn("WeatherSurface", (ROOT / "Modules/Weather" / view).read_text())

    def test_old_weather_shaders_removed(self):
        for name in ("cloud", "rain", "snow", "stars", "sun"):
            self.assertFalse((ROOT / ("Shaders/frag/weather_%s.frag" % name)).exists())
        self.assertEqual([], [p for p in ROOT.rglob("*.qml") if "weather_" in p.read_text() and ".frag.qsb" in p.read_text()])


class DesktopWeatherConventionTests(unittest.TestCase):
    WIDGETS = ("DesktopWeather", "DesktopWeatherHourly", "DesktopWeatherDaily", "DesktopWeatherDetail")

    def test_sized_like_other_desktop_widgets(self):
        # Other desktop widgets size in widgetScale units with Style.marginM
        # padding; the weather ones looked oversized with their own scale.
        for name in self.WIDGETS:
            source = (ROOT / ("Modules/DesktopWidgets/Widgets/%s.qml" % name)).read_text()
            with self.subTest(widget=name):
                self.assertIn("WeatherWidget.desktopSize(", source)
                self.assertIn("Style.marginM * widgetScale", source)
                self.assertNotIn("uiScaleRatio", source)
                self.assertNotIn("Style.marginL", source)

    def test_current_weather_uses_shared_background_by_default(self):
        # The animated sky drew its own grey card over the shared background.
        registry = (ROOT / "Services/UI/DesktopWidgetRegistry.qml").read_text()
        self.assertIn('"animatedSky": false', registry)
        self.assertNotIn('"animatedSky": true', registry)
        source = (ROOT / "Modules/DesktopWidgets/Widgets/DesktopWeather.qml").read_text()
        self.assertIn('widgetSetting("animatedSky") ?? false', source)

    def test_compact_daily_columns_can_fill_available_width(self):
        # Centered labels give a nested layout a finite implicit maximum width.
        # Allow every day to stretch so a five-day strip fills the clock card.
        source = (ROOT / "Modules/Weather/WeatherDaily.qml").read_text()
        compact = source[source.index("model: root.compact ? root.days : []"):]
        compact = compact[:compact.index("NText {")]
        self.assertIn("Layout.fillWidth: true", compact)
        self.assertIn("Layout.maximumWidth: Infinity", compact)

    def test_forecasts_have_no_rain_gaps(self):
        # A hidden low rain chance left an empty hole under that day.
        for path in ("Modules/Weather/WeatherDaily.qml", "Modules/Weather/WeatherHourly.qml"):
            source = (ROOT / path).read_text()
            with self.subTest(path=path):
                self.assertIn("WeatherWidget.precipitationLabel(modelData.precipitationProbability)", source)
                self.assertNotIn('>= 10 ?', source)

if __name__ == "__main__":
    unittest.main()
