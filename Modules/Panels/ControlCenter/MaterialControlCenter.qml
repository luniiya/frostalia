import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import qs.Commons
import qs.Modules.Cards
import qs.Services.Media
import qs.Widgets

Item {
  id: root
  property var screen
  implicitWidth: Math.round(440 * Style.uiScaleRatio)
  implicitHeight: Math.min(content.implicitHeight + Style.margin2S, Math.round(980 * Style.uiScaleRatio))
  readonly property var shortcutRows: ControlCenterLayout.shortcutRows(Settings.data.controlCenter.shortcuts.left, Settings.data.controlCenter.shortcuts.right)
  readonly property var cards: ControlCenterLayout.visibleCards(Settings.data.controlCenter.cards, Settings.data.location.weatherEnabled, shortcutRows.length > 0)

  ScrollView {
    anchors.fill: parent
    anchors.margins: Style.marginS
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ColumnLayout {
      id: content
      width: parent.width
      spacing: Style.marginS
      Repeater {
        model: root.cards
        Loader {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: item?.implicitHeight || 0
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
            case "media-sysmon-card":
              return mediaSysmonCard;
            case "notification-card":
              return notificationCard;
            case "calendar-month-card":
              return calendarCard;
            case "weather-card":
              return weatherCard;
            default:
              return null;
            }
          }
        }
      }
    }
  }

  Component {
    id: profileCard
    MaterialControlHeader {
      screen: root.screen
    }
  }
  Component {
    id: audioCard
    MaterialSliders {
      screen: root.screen
      showAudio: true
      showBrightness: false
    }
  }
  Component {
    id: brightnessCard
    MaterialSliders {
      screen: root.screen
      showAudio: false
      showBrightness: true
    }
  }
  Component {
    id: shortcutsCard
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: tiles.implicitHeight + Style.margin2S
      radius: Style.radiusM
      color: Color.mSurfaceVariant
      ColumnLayout {
        id: tiles
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.marginS
        spacing: Style.marginXS
        Repeater {
          model: root.shortcutRows
          RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: Style.marginXS
            Repeater {
              model: modelData
              MaterialShortcut {
                required property var modelData
                Layout.preferredWidth: ControlCenterLayout.cellWidth(tiles.width, Style.marginXS, modelData.span)
                Layout.preferredHeight: implicitHeight
                entry: modelData
                screen: root.screen
              }
            }
            Item {
              Layout.fillWidth: true
            }
          }
        }
      }
    }
  }
  Component {
    id: mediaSysmonCard
    ColumnLayout {
      spacing: Style.marginS
      Loader {
        Layout.fillWidth: true
        Layout.preferredHeight: item?.implicitHeight || 0
        active: !!MediaService.currentPlayer
        visible: active
        sourceComponent: MediaCard {}
      }
      Loader {
        Layout.fillWidth: true
        Layout.preferredHeight: item?.implicitHeight || 0
        sourceComponent: MaterialSystemMonitor {}
      }
    }
  }
  Component {
    id: notificationCard
    NotificationFeed {}
  }
  Component {
    id: calendarCard
    CalendarMonthCard {}
  }
  Component {
    id: weatherCard
    WeatherCard {}
  }
}
