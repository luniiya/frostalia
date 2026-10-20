import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.Location
import qs.Widgets
import "../../../../../Helpers/WeatherData.js" as WeatherData

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  // Language
  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("panels.general.language-select-label")
    description: I18n.tr("panels.general.language-select-description")
    defaultValue: Settings.getDefaultValue("general.language")
    model: [
      {
        "key": "",
        "name": I18n.tr("panels.general.language-select-auto-detect") + " (" + I18n.systemDetectedLangCode + ")"
      }
    ].concat(I18n.availableLanguages.map(function (langCode) {
      return {
        "key": langCode,
        "name": langCode
      };
    }))
    currentKey: Settings.data.general.language
    settingsPath: "general.language"
    onSelected: key => {
      // Need to change language on next frame using "callLater" or it will pull the rug below our feet: the NComboBox would be rebuilt immediately before it can close properly.
      Qt.callLater(() => {
        Settings.data.general.language = key;
        if (key === "") {
          I18n.detectLanguage(); // Re-detect system language if "Automatic" is selected
        } else {
          I18n.setLanguage(key); // Set specific language
        }
      });
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // Location
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    // Auto-locate
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NToggle {
        Layout.fillWidth: true
        label: I18n.tr("panels.location.auto-locate-label")
        description: I18n.tr("panels.location.auto-locate-description")
        checked: Settings.data.location.autoLocate
        onToggled: checked => Settings.data.location.autoLocate = checked
        defaultValue: Settings.getDefaultValue("location.autoLocate")
      }

      NButton {
        text: I18n.tr("panels.location.geolocate-now-button")
        icon: "current-location"
        enabled: !LocationService.isFetchingWeather
        onClicked: LocationService.geolocateAndApply()
      }
    }

    NTextInput {
      visible: !Settings.data.location.autoLocate
      Layout.maximumWidth: root.width / 2
      label: I18n.tr("panels.location.location-search-label")
      description: I18n.tr("panels.location.location-search-description")
      text: Settings.data.location.name
      placeholderText: I18n.tr("panels.location.location-search-placeholder")
      onEditingFinished: {
        // Verify the location has really changed to avoid extra resets
        var newLocation = text.trim();
        if (newLocation != Settings.data.location.name) {
          Settings.data.location.name = newLocation;
          LocationService.resetWeather();
        }
      }
    }

    NText {
      text: LocationService.coordinatesReady ? I18n.tr("system.location-display", {
                                                         "name": LocationService.stableName,
                                                         "coordinates": LocationService.displayCoordinates
                                                       }) : ""
      pointSize: Style.fontSizeS
      color: ShellColors.mOnSurfaceVariant
      font.italic: true
    }
  }

  ColumnLayout {
    spacing: Style.marginL
    Layout.fillWidth: true

    NToggle {
      label: I18n.tr("panels.location.weather-enabled-label")
      description: I18n.tr("panels.location.weather-enabled-description")
      checked: Settings.data.location.weatherEnabled
      onToggled: checked => Settings.data.location.weatherEnabled = checked
      defaultValue: Settings.getDefaultValue("location.weatherEnabled")
    }

    NToggle {
      label: I18n.tr("panels.location.weather-fahrenheit-label")
      description: I18n.tr("panels.location.weather-fahrenheit-description")
      checked: Settings.data.location.useFahrenheit
      onToggled: checked => Settings.data.location.useFahrenheit = checked
      enabled: Settings.data.location.weatherEnabled
    }

    NToggle {
      label: I18n.tr("panels.location.weather-show-effects-label")
      description: I18n.tr("panels.location.weather-show-effects-description")
      checked: Settings.data.location.weatherShowEffects
      onToggled: checked => Settings.data.location.weatherShowEffects = checked
      enabled: Settings.data.location.weatherEnabled
    }

    NToggle {
      label: I18n.tr("panels.location.weather-hide-city-label")
      description: I18n.tr("panels.location.weather-hide-city-description")
      checked: Settings.data.location.hideWeatherCityName
      onToggled: checked => Settings.data.location.hideWeatherCityName = checked
      enabled: Settings.data.location.weatherEnabled
    }

    NToggle {
      label: I18n.tr("panels.location.weather-hide-timezone-label")
      description: I18n.tr("panels.location.weather-hide-timezone-description")
      checked: Settings.data.location.hideWeatherTimezone
      onToggled: checked => Settings.data.location.hideWeatherTimezone = checked
      enabled: Settings.data.location.weatherEnabled
    }

    NComboBox {
      Layout.fillWidth: true
      label: I18n.tr("panels.location.weather-wind-unit-label")
      description: I18n.tr("panels.location.weather-wind-unit-description")
      enabled: Settings.data.location.weatherEnabled
      minimumWidth: 160 * Style.uiScaleRatio
      model: WeatherData.windUnits.map(unit => ({
                                                  "key": unit,
                                                  "name": WeatherData.windUnitLabel(unit)
                                                }))
      currentKey: Settings.data.location.windSpeedUnit
      onSelected: key => Settings.data.location.windSpeedUnit = key
      defaultValue: Settings.getDefaultValue("location.windSpeedUnit")
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // What the weather panel shows
  ColumnLayout {
    spacing: Style.marginL
    Layout.fillWidth: true
    enabled: Settings.data.location.weatherEnabled

    NLabel {
      label: I18n.tr("panels.location.weather-panel-title")
      description: I18n.tr("panels.location.weather-panel-desc")
    }

    NToggle {
      label: I18n.tr("panels.location.weather-show-hourly-label")
      description: I18n.tr("panels.location.weather-show-hourly-description")
      checked: Settings.data.location.weatherShowHourly
      onToggled: checked => Settings.data.location.weatherShowHourly = checked
      defaultValue: Settings.getDefaultValue("location.weatherShowHourly")
    }

    NSpinBox {
      Layout.fillWidth: true
      visible: Settings.data.location.weatherShowHourly
      label: I18n.tr("panels.location.weather-hourly-count-label")
      description: I18n.tr("panels.location.weather-hourly-count-description")
      from: 6
      to: 48
      stepSize: 6
      value: Settings.data.location.weatherHourlyCount
      onValueChanged: Settings.data.location.weatherHourlyCount = value
      defaultValue: Settings.getDefaultValue("location.weatherHourlyCount")
    }

    NToggle {
      label: I18n.tr("panels.location.weather-show-daily-label")
      description: I18n.tr("panels.location.weather-show-daily-description")
      checked: Settings.data.location.weatherShowDaily
      onToggled: checked => Settings.data.location.weatherShowDaily = checked
      defaultValue: Settings.getDefaultValue("location.weatherShowDaily")
    }

    NSpinBox {
      Layout.fillWidth: true
      visible: Settings.data.location.weatherShowDaily
      label: I18n.tr("panels.location.weather-daily-count-label")
      description: I18n.tr("panels.location.weather-daily-count-description")
      from: 3
      to: 7
      value: Settings.data.location.weatherDailyCount
      onValueChanged: Settings.data.location.weatherDailyCount = value
      defaultValue: Settings.getDefaultValue("location.weatherDailyCount")
    }

    NToggle {
      label: I18n.tr("panels.location.weather-show-details-label")
      description: I18n.tr("panels.location.weather-show-details-description")
      checked: Settings.data.location.weatherShowDetails
      onToggled: checked => Settings.data.location.weatherShowDetails = checked
      defaultValue: Settings.getDefaultValue("location.weatherShowDetails")
    }

    NReorderCheckboxes {
      Layout.fillWidth: true
      visible: Settings.data.location.weatherShowDetails
      model: WeatherData.detailEntries(Settings.data.location.weatherDetails).map(entry => ({
                                                                                            "id": entry.id,
                                                                                            "text": I18n.tr("weather.details." + entry.id),
                                                                                            "enabled": entry.enabled
                                                                                          }))
      onItemToggled: (index, enabled) => Settings.data.location.weatherDetails = WeatherData.toggledDetail(Settings.data.location.weatherDetails, index, enabled)
      onItemsReordered: (fromIndex, toIndex) => Settings.data.location.weatherDetails = WeatherData.movedDetail(Settings.data.location.weatherDetails, fromIndex, toIndex)
    }
  }
}
