import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/SettingsWindowLayout.js" as SettingsWindowLayout
import qs.Commons
import qs.Services.System
import qs.Widgets

NScrollView {
  id: root
  required property var tabs
  readonly property bool material: Style.materialControls
  readonly property var homeMetrics: SettingsWindowLayout.homeMetrics(availableWidth, Style.uiScaleRatio, material)
  readonly property var profile: SettingsWindowLayout.profile(HostService.displayName, HostService.username, HostService.osPretty, I18n.tr("panels.settings.os"), HostService.hostName)
  signal tabRequested(int index)

  horizontalPolicy: ScrollBar.AlwaysOff
  verticalPolicy: ScrollBar.AsNeeded
  reserveScrollbarSpace: false
  leftPadding: material ? Math.round(24 * Style.uiScaleRatio) : Style.marginL
  userRightPadding: leftPadding
  topPadding: leftPadding
  bottomPadding: leftPadding

  ColumnLayout {
    id: homeColumn
    width: root.homeMetrics.contentWidth
    x: Math.max(0, (root.availableWidth - width) / 2)
    spacing: root.material ? Math.round(24 * Style.uiScaleRatio) : Style.marginL

    RowLayout {
      Layout.fillWidth: true
      NText {
        Layout.fillWidth: true
        text: I18n.tr("common.settings")
        pointSize: root.material ? Style.fontSizeXXXL : Style.fontSizeXL
        font.weight: root.material ? Style.fontWeightRegular : Style.fontWeightBold
        color: root.material ? ShellColors.mOnSurface : ShellColors.mPrimary
      }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: profileRow.implicitHeight + Style.margin2L
      radius: Style.radiusM
      color: root.material ? Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mOnSurface, 0.035)) : ShellColors.mSurface
      border.width: root.material ? 0 : Style.boxBorderWidth
      border.color: Style.boxBorderColor

      RowLayout {
        id: profileRow
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginL

        NImageRounded {
          Layout.preferredWidth: root.homeMetrics.avatarSize
          Layout.preferredHeight: width
          radius: width / 2
          imagePath: Settings.preprocessPath(Settings.data.general.avatarImage || Settings.defaultAvatar)
          fallbackIcon: "person"
          borderColor: root.material ? "transparent" : ShellColors.mPrimary
          borderWidth: root.material ? 0 : Style.borderS
        }
        NText {
          id: profileName
          Layout.fillWidth: true
          Layout.preferredWidth: 0
          text: root.profile.name
          pointSize: Style.fontSizeXL
          font.weight: root.material ? Style.fontWeightRegular : Style.fontWeightSemiBold
          color: ShellColors.mOnSurface
          elide: Text.ElideRight
        }
        ColumnLayout {
          id: profileHost
          Layout.fillWidth: true
          Layout.preferredWidth: 0
          visible: root.profile.hostname !== ""
          spacing: Style.marginS
          NText {
            Layout.fillWidth: true
            text: I18n.tr("panels.about.system-host")
            pointSize: Style.fontSizeS
            color: ShellColors.mOnSurfaceVariant
          }
          NText {
            Layout.fillWidth: true
            text: root.profile.hostname
            pointSize: Style.fontSizeM
            color: ShellColors.mOnSurface
            elide: Text.ElideRight
          }
        }
        ColumnLayout {
          id: profileOs
          Layout.fillWidth: true
          Layout.preferredWidth: 0
          spacing: Style.marginS
          NText {
            Layout.fillWidth: true
            text: I18n.tr("panels.settings.os")
            pointSize: Style.fontSizeS
            color: ShellColors.mOnSurfaceVariant
          }
          NText {
            Layout.fillWidth: true
            text: root.profile.os
            pointSize: Style.fontSizeM
            color: ShellColors.mOnSurface
            elide: Text.ElideRight
          }
        }
      }
    }

    GridLayout {
      id: categories
      readonly property var geometry: SettingsWindowLayout.homeGrid(width, Style.uiScaleRatio, root.material)
      Layout.fillWidth: true
      columns: geometry.columns
      rowSpacing: geometry.spacing
      columnSpacing: geometry.spacing

      Repeater {
        model: root.tabs
        delegate: Rectangle {
          id: category
          required property int index
          required property var modelData
          Layout.preferredWidth: categories.geometry.cardWidth
          Layout.fillWidth: true
          implicitHeight: Math.round((root.material ? 112 : 100) * Style.uiScaleRatio)
          radius: Style.radiusM
          color: root.material ? Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mOnSurface, 0.035)) : categoryMouse.containsMouse ? ShellColors.mHover : ShellColors.mSurface
          border.width: root.material ? 0 : Style.boxBorderWidth
          border.color: Style.boxBorderColor

          NMaterialStateLayer {
            hovered: categoryMouse.containsMouse
            pressed: categoryMouse.pressed
            tint: ShellColors.mOnSurface
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginS
            NIcon {
              icon: category.modelData.icon
              color: root.material ? ShellColors.mOnSurface : categoryMouse.containsMouse ? ShellColors.mOnHover : ShellColors.mPrimary
              pointSize: Style.fontSizeXXL
            }
            NText {
              Layout.fillWidth: true
              text: I18n.tr(category.modelData.label)
              pointSize: Style.fontSizeM
              font.weight: root.material ? Style.fontWeightRegular : Style.fontWeightSemiBold
              color: root.material ? ShellColors.mOnSurface : categoryMouse.containsMouse ? ShellColors.mOnHover : ShellColors.mOnSurface
              elide: Text.ElideRight
            }
          }

          MouseArea {
            id: categoryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.tabRequested(category.index)
          }
        }
      }
    }
  }
}
