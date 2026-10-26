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

  // Connected expandable card: header and content are separate tonal pieces
  readonly property var _shape: Style.getExpandableShape(expanded)
  property real _headerBottomRadius: _shape.headerBottom

  Behavior on _headerBottomRadius {
    enabled: root._userInteracted
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
    Layout.preferredHeight: headerContent.implicitHeight + Style.margin2L
    color: ShellColors.mTonalContainer
    topLeftRadius: root._shape.headerTop
    topRightRadius: topLeftRadius
    bottomLeftRadius: root._headerBottomRadius
    bottomRightRadius: root._headerBottomRadius

    // Smooth color transitions
    Behavior on color {
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
        color: headerArea.containsMouse ? ShellColors.mOnSurface : "transparent"
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
      anchors.leftMargin: Style.marginL
      spacing: Style.marginM

      // Header text: headline over supporting text
      GridLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        columns: 1
        columnSpacing: Style.marginL
        rowSpacing: Style.marginXXS

        NText {
          text: root.label
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightSemiBold
          color: ShellColors.mOnSurface
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
          color: ShellColors.mOnSurfaceVariant
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
          visible: root.description !== ""

          Behavior on color {
            enabled: root._userInteracted
            ColorAnimation {
              duration: Style.animationNormal
            }
          }
        }
      }

      // Trailing expand chip that turns primary when open
      Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Style.baseWidgetSize
        implicitHeight: Style.baseWidgetSize
        radius: width / 2
        color: root.expanded ? ShellColors.mPrimary : ShellColors.mSurface

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
          color: root.expanded ? ShellColors.mOnPrimary : ShellColors.mOnSurfaceVariant
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
    Layout.topMargin: root._shape.gap

    visible: root.expanded
    color: ShellColors.mTonalContainer
    topLeftRadius: root._shape.contentTop
    topRightRadius: topLeftRadius
    bottomLeftRadius: root._shape.contentBottom
    bottomRightRadius: bottomLeftRadius

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
