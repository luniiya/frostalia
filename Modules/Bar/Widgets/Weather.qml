import QtQuick
import Quickshell
import "../../../Helpers/WeatherWidget.js" as WeatherWidget
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.Location
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  readonly property string screenName: screen ? screen.name : ""
  readonly property var widgetSettings: Settings.getBarWidgetsForScreen(screenName, section)[section]?.[sectionWidgetIndex] || {}
  readonly property bool isBarVertical: ["left", "right"].indexOf(Settings.getBarPositionForScreen(screenName, section)) >= 0
  readonly property string displayMode: widgetSettings.displayMode ?? widgetMetadata.displayMode
  readonly property string iconColorKey: widgetSettings.iconColor ?? widgetMetadata.iconColor
  readonly property string textColorKey: widgetSettings.textColor ?? widgetMetadata.textColor
  readonly property var weather: WeatherWidget.summary(LocationService.data.weather, Settings.data.location.weatherEnabled, Settings.data.location.useFahrenheit, LocationService.locationConfigured)

  visible: weather.visible
  opacity: weather.visible ? 1 : 0
  implicitWidth: pill.width
  implicitHeight: pill.height

  NPopupContextMenu {
    id: contextMenu
    model: [
      {
        label: I18n.tr("actions.widget-settings"),
        action: "widget-settings",
        icon: "settings"
      }
    ]
    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(root.screen);
      if (action === "widget-settings")
        BarService.openWidgetSettings(root.screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
    }
  }

  BarPill {
    id: pill
    screen: root.screen
    section: root.section
    oppositeDirection: BarService.getPillDirection(root)
    customIconColor: Color.resolveColorKeyOptional(root.iconColorKey)
    customTextColor: Color.resolveColorKeyOptional(root.textColorKey)
    icon: root.weather.ready ? LocationService.weatherSymbolFromCode(root.weather.code) : root.weather.fallbackIcon
    text: root.weather.text
    forceOpen: root.displayMode === "alwaysShow"
    forceClose: root.displayMode === "alwaysHide"
    rotateText: root.isBarVertical
    onClicked: PanelService.getPanel("weatherPanel", root.screen)?.toggle(pill)
    onRightClicked: PanelService.showContextMenu(contextMenu, pill, root.screen)
    tooltipText: {
      if (PanelService.getPanel("weatherPanel", root.screen, false)?.isPanelOpen)
        return "";
      if (!root.weather.ready)
        return I18n.tr(root.weather.statusKey);
      var location = Settings.data.location.hideWeatherCityName ? "" : Settings.data.location.name.split(",")[0];
      return (location ? location + " · " : "") + I18n.tr(root.weather.conditionKey) + " · " + root.weather.text;
    }
  }
}
