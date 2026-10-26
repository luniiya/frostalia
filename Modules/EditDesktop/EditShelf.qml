import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Helpers/EditDesktopGeometry.js" as Geometry
import qs.Commons
import qs.Services.UI
import qs.Widgets

// The shelf of everything that can be put on the desktop: a help panel, framed tiles with a live
// preview of each widget, and Done. Click a tile to add it, or pull it up onto the card.
Rectangle {
  id: root

  // Where the pull is reported, in the coordinates of `dragSpace`
  property Item dragSpace: null
  property ShellScreen screen: null

  signal addAtCenter(string widgetId)
  signal pullStarted(string widgetId)
  signal pullMoved(real x, real y)
  signal pullEnded(real x, real y)
  signal pullCancelled
  signal done

  readonly property color ink: ShellColors.mOnSurface

  color: ShellColors.mSurface
  radius: Style.radiusL
  border.width: Style.borderS
  border.color: Qt.alpha(ShellColors.mOutline, 0.4)

  NStyleCard {}

  RowLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginL

    // Help
    ColumnLayout {
      Layout.preferredWidth: Math.round(190 * Style.uiScaleRatio)
      Layout.fillHeight: true
      spacing: Style.marginS

      NText {
        text: I18n.tr("panels.desktop-widgets.edit-title")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: root.ink
      }

      Repeater {
        model: ["panels.desktop-widgets.edit-hint-add", "panels.desktop-widgets.edit-hint-pull", "panels.desktop-widgets.edit-hint-delete"]

        delegate: RowLayout {
          required property string modelData
          spacing: Style.marginS

          Rectangle {
            width: Style.fontSizeS * 0.8
            height: width
            radius: width / 2
            color: ShellColors.mPrimary
          }
          NText {
            text: I18n.tr(modelData)
            pointSize: Style.fontSizeS
            color: ShellColors.mOnSurfaceVariant
          }
        }
      }
    }

    Rectangle {
      Layout.preferredWidth: 2
      Layout.fillHeight: true
      Layout.topMargin: Style.marginS
      Layout.bottomMargin: Style.marginS
      color: Qt.alpha(ShellColors.mOutline, 0.3)
    }

    ListView {
      id: list
      Layout.fillWidth: true
      Layout.fillHeight: true
      orientation: ListView.Horizontal
      spacing: Style.marginXL
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: EditDesktopService.shelfIds

      delegate: Item {
        id: tile
        required property string modelData
        readonly property int onDesktop: EditDesktopService.countOf(modelData)
        readonly property bool lit: area.containsMouse || area.pulling

        width: Math.round(210 * Style.uiScaleRatio)
        height: list.height

        // Frame with the live preview inside
        Rectangle {
          id: frame
          anchors.fill: parent
          anchors.margins: 6
          anchors.bottomMargin: Style.marginXL
          radius: Style.radiusL
          color: tile.lit ? ShellColors.mHover : ShellColors.mSurfaceVariant
          border.width: tile.lit ? 2 : 0
          border.color: ShellColors.mPrimary

          NStyleCard {
            hovered: area.containsMouse
            pressed: area.pressed
          }

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }

          Item {
            id: stage
            anchors.fill: parent
            anchors.margins: 8
            clip: true

            Item {
              id: holder
              property Item widget: null
              readonly property real fit: widget && widget.implicitWidth > 0 && widget.implicitHeight > 0 ? Math.min(1, stage.width / widget.implicitWidth, stage.height / widget.implicitHeight) : 1

              enabled: false
              width: widget ? widget.implicitWidth : 0
              height: widget ? widget.implicitHeight : 0
              scale: fit
              transformOrigin: Item.TopLeft
              x: (stage.width - width * fit) / 2
              y: (stage.height - height * fit) / 2
            }

            Loader {
              id: preview

              Component.onCompleted: {
                const url = DesktopWidgetRegistry.widgetUrls[tile.modelData];
                if (!url)
                  return;
                const data = Object.assign({}, DesktopWidgetRegistry.widgetMetadata[tile.modelData] || {}, {
                                             "id": tile.modelData,
                                             "x": 0,
                                             "y": 0,
                                             "scale": 1.0
                                           });
                setSource(url, {
                            "screen": root.screen,
                            "widgetData": data,
                            "widgetIndex": -1
                          });
              }
              onLoaded: {
                item.parent = holder;
                item.x = 0;
                item.y = 0;
                item.width = Qt.binding(() => item.implicitWidth);
                item.height = Qt.binding(() => item.implicitHeight);
                holder.widget = item;
              }
            }

            // Fallback while a widget has no size yet or is not loadable
            NIcon {
              anchors.centerIn: parent
              visible: !holder.widget
              icon: Geometry.tileIcon(tile.modelData)
              pointSize: Style.fontSizeXXL
              color: root.ink
            }
          }
        }

        // Name
        NText {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: frame.bottom
          anchors.topMargin: Style.marginXS
          text: DesktopWidgetRegistry.getWidgetDisplayName(tile.modelData)
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightSemiBold
          color: tile.lit ? ShellColors.mPrimary : ShellColors.mOnSurface
        }

        // On the desktop (count) or plus (add)
        Rectangle {
          anchors.right: frame.right
          anchors.top: frame.top
          anchors.margins: Style.marginS
          width: Math.round(24 * Style.uiScaleRatio)
          height: width
          radius: width / 2
          color: tile.onDesktop > 0 ? ShellColors.mSecondary : ShellColors.mPrimary

          NText {
            anchors.centerIn: parent
            visible: tile.onDesktop > 0
            text: tile.onDesktop
            pointSize: Style.fontSizeXS
            font.weight: Style.fontWeightBold
            color: ShellColors.mOnSecondary
          }
          NIcon {
            anchors.centerIn: parent
            visible: tile.onDesktop === 0
            icon: "plus"
            pointSize: Style.fontSizeS
            color: ShellColors.mOnPrimary
          }
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          property bool pulling: false
          property point pressPoint: Qt.point(0, 0)

          // The list scrolls sideways and takes a press for itself after a few pixels: a pull is decided first
          preventStealing: pulling

          onPressed: mouse => {
            pressPoint = Qt.point(mouse.x, mouse.y);
            pulling = false;
          }

          onPositionChanged: mouse => {
            if (!pressed)
              return;
            if (!pulling) {
              const g = Geometry.gesture(mouse.x - pressPoint.x, mouse.y - pressPoint.y);
              if (g !== "pull")
                return;
              pulling = true;
              root.pullStarted(tile.modelData);
            }
            const p = mapToItem(root.dragSpace, mouse.x, mouse.y);
            root.pullMoved(p.x, p.y);
          }

          onReleased: mouse => {
            if (pulling) {
              pulling = false;
              const p = mapToItem(root.dragSpace, mouse.x, mouse.y);
              root.pullEnded(p.x, p.y);
            }
          }

          onCanceled: {
            if (pulling) {
              pulling = false;
              root.pullCancelled();
            }
          }

          onClicked: {
            if (!pulling && Math.abs(mouseX - pressPoint.x) < 10 && Math.abs(mouseY - pressPoint.y) < 10)
              root.addAtCenter(tile.modelData);
          }
        }
      }
    }

    Rectangle {
      Layout.preferredWidth: 2
      Layout.fillHeight: true
      Layout.topMargin: Style.marginS
      Layout.bottomMargin: Style.marginS
      color: Qt.alpha(ShellColors.mOutline, 0.3)
    }

    // Done
    Rectangle {
      Layout.preferredWidth: Math.round(140 * Style.uiScaleRatio)
      Layout.preferredHeight: Math.round(56 * Style.uiScaleRatio)
      Layout.alignment: Qt.AlignVCenter
      radius: height / 2
      color: doneArea.containsMouse ? Qt.lighter(ShellColors.mPrimary, 1.1) : ShellColors.mPrimary

      NStyleCard {
        hovered: doneArea.containsMouse
        pressed: doneArea.pressed
      }

      RowLayout {
        anchors.centerIn: parent
        spacing: Style.marginS

        NIcon {
          icon: "check"
          pointSize: Style.fontSizeL
          color: ShellColors.mOnPrimary
        }
        NText {
          text: I18n.tr("panels.desktop-widgets.edit-done")
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightBold
          color: ShellColors.mOnPrimary
        }
      }

      MouseArea {
        id: doneArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.done()
      }
    }
  }
}
