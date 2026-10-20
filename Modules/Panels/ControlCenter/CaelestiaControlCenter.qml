import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import qs.Commons
import qs.Modules.Cards
import qs.Modules.MainScreen
import qs.Services.Media
import qs.Services.Networking
import qs.Services.System
import qs.Services.UI
import qs.Widgets

Item {
  id: root
  property var screen
  implicitWidth: Math.round(440 * Style.uiScaleRatio)
  implicitHeight: {
    var height = 0;
    var count = 0;
    for (var i = 0; i < Settings.data.controlCenter.cards.length; i++) {
      const card = Settings.data.controlCenter.cards[i];
      if (!card.enabled)
        continue;
      const contributes = ControlCenterLayout.visibleCards([card], Settings.data.location.weatherEnabled, true, KdeConnectService.enabled).length > 0;
      if (!contributes)
        continue;
      count++;
      switch (card.id) {
      case "profile-card":
        height += profileHeight;
        break;
      case "shortcuts-card":
        height += shortcutsHeight;
        break;
      case "audio-card":
        height += audioHeight;
        break;
      case "brightness-card":
        height += brightnessHeight;
        break;
      case "weather-card":
        height += weatherHeight;
        break;
      case "notification-card":
        height += notificationHeight;
        break;
      case "calendar-month-card":
        height += calendarHeight;
        break;
      case "media-sysmon-card":
        height += mediaSysMonHeight;
        break;
      case "kdeconnect-card":
        height += kdeConnectHeight;
        break;
      default:
        break;
      }
    }
    return height + (count + 1) * Style.marginL;
  }

  readonly property int profileHeight: Math.round(64 * Style.uiScaleRatio)
  readonly property int shortcutsHeight: Math.round(52 * Style.uiScaleRatio)
  readonly property int audioHeight: Math.round(60 * Style.uiScaleRatio)
  readonly property int brightnessHeight: Math.round(60 * Style.uiScaleRatio)
  readonly property int mediaSysMonHeight: Math.round(260 * Style.uiScaleRatio)
  readonly property int kdeConnectHeight: Math.round(64 * Style.uiScaleRatio)

  readonly property int notificationHeight: ControlCenterLayout.notificationHeight(NotificationService.historyModel.count, Style.uiScaleRatio)
  property real calendarHeight: Math.round(350 * Style.uiScaleRatio)

  // We keep a dynamic weather height due to a more complex layout and font scaling
  property int weatherHeight: Math.round(210 * Style.uiScaleRatio)

  ColumnLayout {
    id: layout
    x: Style.marginL
    y: Style.marginL
    width: parent.width - Style.margin2L
    spacing: Style.marginL

    Repeater {
      model: Settings.data.controlCenter.cards
      Loader {
        active: ControlCenterLayout.visibleCards([modelData], Settings.data.location.weatherEnabled, true, KdeConnectService.enabled).length > 0
        visible: active
        Layout.fillWidth: true
        Layout.preferredHeight: {
          switch (modelData.id) {
          case "profile-card":
            return profileHeight;
          case "shortcuts-card":
            return shortcutsHeight;
          case "audio-card":
            return audioHeight;
          case "brightness-card":
            return brightnessHeight;
          case "weather-card":
            return weatherHeight;
          case "notification-card":
            return notificationHeight;
          case "calendar-month-card":
            return calendarHeight;
          case "media-sysmon-card":
            return mediaSysMonHeight;
          case "kdeconnect-card":
            return kdeConnectHeight;
          default:
            return 0;
          }
        }
        sourceComponent: {
          switch (modelData.id) {
          case "profile-card":
            return profileCard;
          case "shortcuts-card":
            return shortcutsCard;
          case "audio-card":
            return audioCard;
          case "brightness-card":
            return brightnessCard;
          case "weather-card":
            return weatherCard;
          case "notification-card":
            return notificationCard;
          case "calendar-month-card":
            return calendarCard;
          case "media-sysmon-card":
            return mediaSysMonCard;
          case "kdeconnect-card":
            return kdeConnectCard;
          }
        }
      }
    }
  }

  Component {
    id: notificationCard
    NotificationFeed {}
  }

  Component {
    id: calendarCard
    CalendarMonthCard {
      onImplicitHeightChanged: root.calendarHeight = implicitHeight
      Component.onCompleted: root.calendarHeight = implicitHeight
    }
  }

  Component {
    id: profileCard
    ProfileCard {}
  }

  Component {
    id: kdeConnectCard
    CaelestiaKdeConnectCard {
      id: phoneCard
      onClicked: PanelService.getPanel("kdeConnectPanel", root.screen)?.toggle(phoneCard)
    }
  }

  Component {
    id: shortcutsCard
    ShortcutsCard {}
  }

  Component {
    id: audioCard
    AudioCard {}
  }

  Component {
    id: brightnessCard
    BrightnessCard {}
  }

  Component {
    id: weatherCard
    WeatherCard {
      Component.onCompleted: {
        root.weatherHeight = this.height;
      }
    }
  }

  Component {
    id: mediaSysMonCard
    RowLayout {
      spacing: Style.marginL

      // Media card
      MediaCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
      }

      // System monitors combined in one card
      SystemMonitorCard {
        Layout.preferredWidth: Math.round(Style.baseWidgetSize * 2.625)
        Layout.fillHeight: true
      }
    }
  }
}
