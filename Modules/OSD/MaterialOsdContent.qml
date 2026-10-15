import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var viewModel: ({})
  readonly property bool vertical: viewModel.vertical || false
  readonly property bool lockKey: viewModel.lockKey || false
  readonly property string icon: viewModel.icon || ""
  readonly property string label: viewModel.label || ""
  readonly property string valueText: viewModel.valueText || ""
  readonly property real value: viewModel.value || 0
  readonly property real maximum: viewModel.maximum || 1
  readonly property color accentColor: viewModel.accentColor || Color.mPrimary
  readonly property color onAccentColor: viewModel.onAccentColor || Color.mOnPrimary

  readonly property real unit: Style.uiScaleRatio

  RowLayout {
    anchors.fill: parent
    anchors.margins: 16 * root.unit
    spacing: 14 * root.unit
    visible: !root.vertical || root.lockKey

    Rectangle {
      Layout.preferredWidth: 52 * root.unit
      Layout.preferredHeight: 52 * root.unit
      Layout.alignment: Qt.AlignVCenter
      radius: 20 * root.unit
      color: root.accentColor

      NIcon {
        anchors.centerIn: parent
        icon: root.icon
        pointSize: Style.fontSizeXL
        color: root.onAccentColor
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 10 * root.unit

      RowLayout {
        Layout.fillWidth: true
        spacing: 8 * root.unit

        NText {
          Layout.fillWidth: true
          text: root.lockKey ? root.valueText : root.label
          pointSize: root.lockKey ? Style.fontSizeM : Style.fontSizeS
          font.weight: Style.fontWeightMedium
        }

        NText {
          visible: !root.lockKey
          text: root.valueText
          pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
        }
      }

      MaterialOsdTrack {
        visible: !root.lockKey
        Layout.fillWidth: true
        Layout.preferredHeight: 26 * root.unit
        value: root.value
        maximum: root.maximum
        activeColor: root.accentColor
        inactiveColor: Color.mSurfaceVariant
        markerColor: root.onAccentColor
        animationDuration: Style.animationFast
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16 * root.unit
    spacing: 12 * root.unit
    visible: root.vertical && !root.lockKey

    NText {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: root.valueText
      pointSize: Style.fontSizeM
    }

    MaterialOsdTrack {
      Layout.fillWidth: true
      Layout.fillHeight: true
      vertical: true
      value: root.value
      maximum: root.maximum
      activeColor: root.accentColor
      inactiveColor: Color.mSurfaceVariant
      markerColor: root.onAccentColor
      animationDuration: Style.animationFast
    }

    NIcon {
      Layout.alignment: Qt.AlignHCenter
      icon: root.icon
      color: root.accentColor
      pointSize: Style.fontSizeXL
    }
  }
}
