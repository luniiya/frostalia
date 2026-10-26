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
  readonly property var homeMetrics: SettingsWindowLayout.homeMetrics(availableWidth, Style.uiScaleRatio)
  readonly property var profile: SettingsWindowLayout.profile(HostService.displayName, HostService.username, HostService.osPretty, I18n.tr("panels.settings.os"), HostService.hostName)
  readonly property var homeTabs: SettingsWindowLayout.homeCategories(tabs, SettingsPanel.Tab.General, SettingsPanel.Tab.About, categories.geometry.columns >= 3)
  signal tabRequested(int index)

  horizontalPolicy: ScrollBar.AlwaysOff
  verticalPolicy: ScrollBar.AsNeeded
  reserveScrollbarSpace: false
  leftPadding: Math.round(24 * Style.uiScaleRatio)
  userRightPadding: leftPadding
  topPadding: leftPadding
  bottomPadding: leftPadding

  component CategoryCard: Rectangle {
    id: category
    required property var entry
    property bool compact: false
    signal chosen(int tabIndex)
    implicitHeight: compact ? root.homeMetrics.avatarSize + Style.margin2L : Math.round(112 * Style.uiScaleRatio)
    radius: Style.radiusM
    color: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mOnSurface, 0.035))
    border.width: 0
    border.color: Style.boxBorderColor

    NStyleCard {
      hovered: categoryMouse.containsMouse
      pressed: categoryMouse.pressed
    }

    NMaterialStateLayer {
      hovered: categoryMouse.containsMouse
      pressed: categoryMouse.pressed
      tint: ShellColors.mOnSurface
    }

    ColumnLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: category.compact ? undefined : parent.top
      anchors.bottom: category.compact ? undefined : parent.bottom
      anchors.verticalCenter: category.compact ? parent.verticalCenter : undefined
      anchors.margins: Style.marginL
      spacing: Style.marginS
      NIcon {
        Layout.alignment: category.compact ? Qt.AlignHCenter : Qt.AlignLeft
        icon: category.entry ? category.entry.tab.icon : ""
        color: ShellColors.mOnSurface
        pointSize: Style.fontSizeXXL
      }
      NText {
        Layout.fillWidth: true
        horizontalAlignment: category.compact ? Text.AlignHCenter : Text.AlignLeft
        text: category.entry ? I18n.tr(category.entry.tab.label) : ""
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightRegular
        color: ShellColors.mOnSurface
        elide: Text.ElideRight
      }
    }

    MouseArea {
      id: categoryMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (category.entry)
          category.chosen(category.entry.index);
      }
    }
  }

  ColumnLayout {
    id: homeColumn
    width: root.homeMetrics.contentWidth
    x: Math.max(0, (root.availableWidth - width) / 2)
    spacing: Math.round(24 * Style.uiScaleRatio)

    RowLayout {
      Layout.fillWidth: true
      NText {
        Layout.fillWidth: true
        text: I18n.tr("common.settings")
        pointSize: Style.fontSizeXXXL
        font.weight: Style.fontWeightRegular
        color: ShellColors.mOnSurface
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: categories.geometry.spacing

      CategoryCard {
        visible: root.homeTabs.promoted
        entry: root.homeTabs.general
        compact: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        onChosen: tabIndex => root.tabRequested(tabIndex)
      }

      Rectangle {
        Layout.preferredWidth: categories.geometry.profileWidth
        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        implicitHeight: profileRow.implicitHeight + Style.margin2L
        radius: Style.radiusM
        color: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mOnSurface, 0.035))
        border.width: 0
        border.color: Style.boxBorderColor

        NStyleCard {}

        Item {
          id: profileRow
          anchors.fill: parent
          anchors.margins: Style.marginL
          implicitHeight: root.homeMetrics.avatarSize

          NImageRounded {
            id: profileAvatar
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.homeMetrics.avatarSize
            height: width
            radius: width / 2
            imagePath: Settings.preprocessPath(Settings.data.general.avatarImage || Settings.defaultAvatar)
            fallbackIcon: "person"
            borderColor: "transparent"
            borderWidth: 0
          }

          NText {
            id: profileName
            anchors.left: profileAvatar.right
            anchors.leftMargin: Style.marginL
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width / 3 - profileAvatar.width - Style.marginL)
            text: root.profile.name
            pointSize: Style.fontSizeXL
            font.weight: Style.fontWeightRegular
            color: ShellColors.mOnSurface
            elide: Text.ElideRight
          }

          NText {
            id: profileHost
            anchors.centerIn: parent
            width: parent.width / 3
            horizontalAlignment: Text.AlignHCenter
            text: root.profile.hostname
            font: profileName.font
            color: profileName.color
            elide: Text.ElideRight
          }

          RowLayout {
            id: profileOs
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width / 3
            spacing: Style.marginM

            NText {
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignRight
              text: root.profile.os
              font: profileName.font
              color: profileName.color
              elide: Text.ElideRight
            }

            Image {
              visible: HostService.osLogo !== ""
              source: HostService.osLogo
              Layout.preferredWidth: profileAvatar.width
              Layout.preferredHeight: profileAvatar.height
              fillMode: Image.PreserveAspectFit
              sourceSize.width: width
              sourceSize.height: height
              asynchronous: true
            }
          }
        }
      }

      CategoryCard {
        visible: root.homeTabs.promoted
        entry: root.homeTabs.about
        compact: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        onChosen: tabIndex => root.tabRequested(tabIndex)
      }
    }

    GridLayout {
      id: categories
      readonly property var geometry: SettingsWindowLayout.homeGrid(width, Style.uiScaleRatio)
      Layout.fillWidth: true
      columns: geometry.columns
      rowSpacing: geometry.spacing
      columnSpacing: geometry.spacing

      Repeater {
        model: root.homeTabs.grid
        delegate: CategoryCard {
          required property var modelData
          entry: modelData
          Layout.preferredWidth: categories.geometry.cardWidth
          Layout.fillWidth: true
          onChosen: tabIndex => root.tabRequested(tabIndex)
        }
      }
    }
  }
}
