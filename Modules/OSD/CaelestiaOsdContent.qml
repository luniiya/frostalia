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
  readonly property string valueText: viewModel.valueText || ""
  readonly property real value: viewModel.value || 0
  readonly property real maximum: viewModel.maximum || 1
  readonly property color accentColor: viewModel.accentColor || Color.mPrimary
  readonly property color iconColor: viewModel.iconColor || Color.mOnSurface
  readonly property real barThickness: viewModel.barThickness || 8

  Loader {
    anchors.fill: parent
    sourceComponent: root.vertical ? verticalContent : horizontalContent
  }

  Component {
    id: horizontalContent
    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.marginL
      anchors.rightMargin: Style.marginL
      spacing: Style.marginM

      TextMetrics {
        id: percentageMetrics
        font.family: Style.fontFixed
        font.pointSize: Style.fontSizeS * (Settings.data.ui.fontFixedScale * Style.uiScaleRatio)
        text: "150%"
      }

      // Common Icon for all types
      NIcon {
        icon: root.icon
        color: root.iconColor
        pointSize: Style.fontSizeXL
        Layout.alignment: Qt.AlignVCenter

        Behavior on color {
          ColorAnimation {
            duration: Style.animationNormal
            easing.type: Easing.InOutQuad
          }
        }
      }

      // Lock Key Status Text (replaces progress bar)
      NText {
        visible: root.lockKey
        text: root.valueText
        color: root.accentColor
        pointSize: Style.fontSizeS
        elide: Text.ElideNone
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignVCenter
      }

      // Progress Bar for Volume/Brightness
      Rectangle {
        visible: !root.lockKey
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        height: root.barThickness
        radius: Math.min(Style.iRadiusL, root.barThickness / 2)
        color: Color.mSurfaceVariant

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: parent.width * Math.min(1.0, root.value / root.maximum)
          radius: parent.radius
          color: root.accentColor

          Behavior on width {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.InOutQuad
            }
          }
          Behavior on color {
            ColorAnimation {
              duration: Style.animationNormal
              easing.type: Easing.InOutQuad
            }
          }
        }
      }

      // Percentage Text for Volume/Brightness
      NText {
        visible: !root.lockKey
        text: root.valueText
        color: Color.mOnSurface
        pointSize: Style.fontSizeS
        family: Style.fontFixed
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        Layout.fillWidth: false
        Layout.preferredWidth: Math.ceil(percentageMetrics.width) + Math.round(8 * Style.uiScaleRatio)
        Layout.maximumWidth: Math.ceil(percentageMetrics.width) + Math.round(8 * Style.uiScaleRatio)
        Layout.minimumWidth: Math.ceil(percentageMetrics.width)
      }
    }
  }

  Component {
    id: verticalContent
    ColumnLayout {
      anchors.fill: parent
      anchors.topMargin: Style.marginL
      anchors.bottomMargin: Style.marginL
      spacing: root.lockKey ? Style.marginM : Style.marginS
      clip: !root.lockKey

      ColumnLayout {
        id: textVerticalLayout
        visible: root.lockKey
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignHCenter
        spacing: 0

        readonly property var verticalTextChars: root.valueText.split("")

        Repeater {
          model: textVerticalLayout.verticalTextChars

          NText {
            text: modelData || ""
            color: root.accentColor
            pointSize: Style.fontSizeS
            family: Style.fontFixed
            Layout.fillWidth: true
            Layout.preferredHeight: {
              const fontSize = Style.fontSizeS * Settings.data.ui.fontFixedScale * Style.uiScaleRatio;
              return Math.round(fontSize * 1.3);
            }
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }
      }

      NText {
        visible: !root.lockKey
        text: root.valueText
        color: Color.mOnSurface
        pointSize: Style.fontSizeS
        family: Style.fontFixed
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Layout.preferredHeight: Math.round(20 * Style.uiScaleRatio)
      }

      Item {
        visible: !root.lockKey
        Layout.fillWidth: true
        Layout.fillHeight: !root.lockKey

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: root.barThickness
          radius: Math.min(Style.iRadiusL, root.barThickness / 2)
          color: Color.mSurfaceVariant

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * Math.min(1.0, root.value / root.maximum)
            radius: parent.radius
            color: root.accentColor

            Behavior on height {
              NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.InOutQuad
              }
            }
            Behavior on color {
              ColorAnimation {
                duration: Style.animationNormal
                easing.type: Easing.InOutQuad
              }
            }
          }
        }
      }

      NIcon {
        icon: root.icon
        color: root.iconColor
        pointSize: root.lockKey ? Style.fontSizeXL : Style.fontSizeL
        Layout.alignment: root.lockKey ? Qt.AlignHCenter : (Qt.AlignHCenter | Qt.AlignBottom)
        Layout.preferredHeight: root.lockKey ? (Style.fontSizeXL * Style.uiScaleRatio * 1.5) : -1
        Layout.minimumHeight: root.lockKey ? (Style.fontSizeXL * Style.uiScaleRatio) : 0

        Behavior on color {
          ColorAnimation {
            duration: Style.animationNormal
            easing.type: Easing.InOutQuad
          }
        }
      }
    }
  }
}
