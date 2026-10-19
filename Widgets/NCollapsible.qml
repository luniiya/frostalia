import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  property bool expanded: false
  property real contentSpacing: Style.marginM
  property bool _userInteracted: false

  // Material: connected expandable card; null keeps the Caelestia look.
  readonly property var _shape: Style.getExpandableShape(expanded)
  readonly property bool _material: _shape !== null
  property real _headerBottomRadius: _material ? _shape.headerBottom : Style.iRadiusM

  Behavior on _headerBottomRadius {
    enabled: root._material && root._userInteracted
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  signal toggled(bool expanded)

  Layout.fillWidth: true
  spacing: 0

  // Default property to accept children
  default property alias content: contentLayout.children

  // Header with clickable area
  Rectangle {
    id: headerContainer
    Layout.fillWidth: true
    Layout.preferredHeight: headerContent.implicitHeight + (root._material ? Style.margin2L : Style.margin2M)
    color: root._material ? Color.mTonalContainer : (root.expanded ? Color.mSecondary : Color.mPrimary)
    topLeftRadius: root._material ? root._shape.headerTop : Style.iRadiusM
    topRightRadius: topLeftRadius
    bottomLeftRadius: root._headerBottomRadius
    bottomRightRadius: root._headerBottomRadius
    border.color: root.expanded ? Color.mOnSecondary : Color.mOutline
    border.width: root._material ? 0 : Style.borderS

    // Smooth color transitions
    Behavior on color {
      enabled: root._userInteracted
      ColorAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }

    Behavior on border.color {
      enabled: root._userInteracted
      ColorAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }

    MouseArea {
      id: headerArea
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true

      onClicked: {
        root._userInteracted = true;
        root.expanded = !root.expanded;
        root.toggled(root.expanded);
      }

      // Hover effect overlay
      Rectangle {
        anchors.fill: parent
        color: headerArea.containsMouse ? Color.mOnSurface : "transparent"
        opacity: headerArea.containsMouse ? 0.08 : 0
        topLeftRadius: headerContainer.topLeftRadius
        topRightRadius: headerContainer.topRightRadius
        bottomLeftRadius: headerContainer.bottomLeftRadius
        bottomRightRadius: headerContainer.bottomRightRadius

        Behavior on opacity {
          NumberAnimation {
            duration: Style.animationFast
          }
        }
      }
    }

    RowLayout {
      id: headerContent
      anchors.fill: parent
      anchors.margins: Style.marginM
      anchors.leftMargin: root._material ? Style.marginL : Style.marginM
      spacing: Style.marginM

      // Expand/collapse icon with rotation animation
      NIcon {
        id: chevronIcon
        visible: !root._material
        icon: "chevron-right"
        pointSize: Style.fontSizeL
        color: root.expanded ? Color.mOnSecondary : Color.mOnPrimary
        Layout.alignment: Qt.AlignVCenter

        rotation: root.expanded ? 90 : 0
        Behavior on rotation {
          enabled: root._userInteracted
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
          }
        }

        Behavior on color {
          enabled: root._userInteracted
          ColorAnimation {
            duration: Style.animationNormal
          }
        }
      }

      // Header text content: side by side, or headline over supporting text on Material
      GridLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        columns: root._material ? 1 : 2
        columnSpacing: Style.marginL
        rowSpacing: Style.marginXXS

        NText {
          text: root.label
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightSemiBold
          color: root._material ? Color.mOnSurface : (root.expanded ? Color.mOnSecondary : Color.mOnPrimary)
          wrapMode: Text.WordWrap

          Behavior on color {
            enabled: root._userInteracted
            ColorAnimation {
              duration: Style.animationNormal
            }
          }
        }

        NText {
          text: root.description
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightRegular
          color: root._material ? Color.mOnSurfaceVariant : (root.expanded ? Color.mOnSecondary : Color.mOnPrimary)
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
          visible: root.description !== ""
          opacity: root._material ? 1 : 0.87

          Behavior on color {
            enabled: root._userInteracted
            ColorAnimation {
              duration: Style.animationNormal
            }
          }
        }
      }

      // Material: trailing expand chip that turns primary when open
      Rectangle {
        visible: root._material
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Style.baseWidgetSize
        implicitHeight: Style.baseWidgetSize
        radius: width / 2
        color: root.expanded ? Color.mPrimary : Color.mSurface

        Behavior on color {
          enabled: root._userInteracted
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
          }
        }

        NIcon {
          anchors.centerIn: parent
          icon: "chevron-down"
          pointSize: Style.fontSizeL
          color: root.expanded ? Color.mOnPrimary : Color.mOnSurfaceVariant
          rotation: root.expanded ? 180 : 0

          Behavior on rotation {
            enabled: root._userInteracted
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutCubic
            }
          }
        }
      }
    }
  }

  // Collapsible content with Material 3 styling
  Rectangle {
    id: contentContainer
    Layout.fillWidth: true
    Layout.topMargin: root._material ? root._shape.gap : Style.marginS

    visible: root.expanded
    color: root._material ? Color.mTonalContainer : Color.mSurface
    topLeftRadius: root._material ? root._shape.contentTop : Style.iRadiusL
    topRightRadius: topLeftRadius
    bottomLeftRadius: root._material ? root._shape.contentBottom : Style.iRadiusL
    bottomRightRadius: bottomLeftRadius
    border.color: Color.mOutline
    border.width: root._material ? 0 : Style.borderS

    // Dynamic height based on content
    Layout.preferredHeight: expanded ? contentLayout.implicitHeight + Style.margin2L : 0

    // Smooth height animation
    Behavior on Layout.preferredHeight {
      enabled: root._userInteracted
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }

    // Content layout
    ColumnLayout {
      id: contentLayout
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: root.contentSpacing
    }

    // Fade in animation for content
    opacity: root.expanded ? 1.0 : 0.0
    Behavior on opacity {
      enabled: root._userInteracted
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }
  }
}
