import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Helpers/EditDesktopGeometry.js" as Geometry
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Services.UI
import qs.Widgets

// The Edit Desktop screen: the desktop shrinks into a framed card on a dark stage. One full-screen
// Overlay window per monitor; only the monitor being edited gets the card, the others get the stage.
Variants {
  id: root
  model: Quickshell.screens

  delegate: Loader {
    id: screenLoader
    required property ShellScreen modelData

    active: EditDesktopService.shown

    sourceComponent: PanelWindow {
      id: window
      screen: screenLoader.modelData
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.keyboardFocus: isMain && EditDesktopService.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      WlrLayershell.namespace: "frostalia-edit-desktop-" + (screen?.name || "unknown")

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      readonly property bool isMain: screenLoader.modelData.name === EditDesktopService.screenName
      readonly property real progress: EditDesktopService.progress
      readonly property var rect: EditDesktopService.cardRect(width, height)
      readonly property var stage: Geometry.stageTransform(progress, rect)
      readonly property string wallpaper: WallpaperService.getWallpaper(screenLoader.modelData.name)
      readonly property Item selectedItem: isMain ? widgetLayer.itemAt(EditDesktopService.selectedIndex) : null

      Shortcut {
        sequence: "Escape"
        enabled: window.isMain
        onActivated: EditDesktopService.back()
      }
      Shortcut {
        sequence: "Ctrl+Z"
        enabled: window.isMain && DesktopWidgetRegistry.canUndo
        onActivated: DesktopWidgetRegistry.undo()
      }
      Shortcut {
        sequences: ["Ctrl+Shift+Z", "Ctrl+Y"]
        enabled: window.isMain && DesktopWidgetRegistry.canRedo
        onActivated: DesktopWidgetRegistry.redo()
      }
      Shortcut {
        sequence: "Delete"
        enabled: window.isMain && window.selectedItem !== null
        onActivated: {
          window.selectedItem.removeWidget();
          EditDesktopService.select(-1);
        }
      }

      // Everything is drawn into this item; it is also where the shelf reports the pointer
      Item {
        id: space
        anchors.fill: parent
        opacity: Math.min(1, window.progress * 4)

        EditBackdrop {
          anchors.fill: parent
          opacity: window.progress
          wallpaper: window.wallpaper
        }

        // The desktop, at its real size, scaled into the card
        Item {
          id: card
          visible: window.isMain
          width: window.width
          height: window.height
          transformOrigin: Item.TopLeft
          x: window.stage.x
          y: window.stage.y
          scale: window.stage.scale

          Image {
            anchors.fill: parent
            source: window.wallpaper ? "file://" + window.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
          }

          EditBarStandIn {
            anchors.fill: parent
            screenName: screenLoader.modelData.name
          }

          EditGridOverlay {
            anchors.fill: parent
            visible: Settings.data.desktopWidgets.gridSnap
            screenWidth: window.width
            screenHeight: window.height
          }

          // Click on the bare card: nothing selected
          MouseArea {
            anchors.fill: parent
            onClicked: EditDesktopService.select(-1)
          }

          DesktopWidgetsLayer {
            id: widgetLayer
            anchors.fill: parent
            screen: screenLoader.modelData
            widgets: EditDesktopService.widgetsOf(screenLoader.modelData.name)
            editing: EditDesktopService.active
          }
        }

        EditFrame {
          anchors.fill: parent
          visible: window.isMain
          opacity: window.progress
          cardX: window.stage.x
          cardY: window.stage.y
          cardWidth: window.width * window.stage.scale
          cardHeight: window.height * window.stage.scale
        }

        // Toolbar above the card
        Rectangle {
          id: toolbar
          visible: window.isMain
          opacity: window.progress
          anchors.horizontalCenter: parent.horizontalCenter
          y: Math.round((EditDesktopService.cardPad - height) / 2) - (1 - window.progress) * height
          width: toolbarRow.implicitWidth + Style.marginM * 2
          height: toolbarRow.implicitHeight + Style.marginS * 2
          radius: height / 2
          color: Qt.alpha(ShellColors.mSurface, 0.94)
          border.width: Style.borderS
          border.color: Qt.alpha(ShellColors.mOutline, 0.5)

          RowLayout {
            id: toolbarRow
            anchors.centerIn: parent
            spacing: Style.marginS

            NIconButton {
              icon: "arrow-back-up"
              tooltipText: I18n.tr("actions.undo-desktop-widget-change")
              enabled: DesktopWidgetRegistry.canUndo
              onClicked: DesktopWidgetRegistry.undo()
            }
            NIconButton {
              icon: "arrow-forward-up"
              tooltipText: I18n.tr("actions.redo-desktop-widget-change")
              enabled: DesktopWidgetRegistry.canRedo
              onClicked: DesktopWidgetRegistry.redo()
            }
            NIconButton {
              icon: "grid-4x4"
              tooltipText: I18n.tr("panels.desktop-widgets.edit-mode-grid-snap-label")
              colorBg: Settings.data.desktopWidgets.gridSnap ? ShellColors.mPrimary : ShellColors.mSurfaceVariant
              colorFg: Settings.data.desktopWidgets.gridSnap ? ShellColors.mOnPrimary : ShellColors.mPrimary
              onClicked: Settings.data.desktopWidgets.gridSnap = !Settings.data.desktopWidgets.gridSnap
            }
            NIconButton {
              visible: Settings.data.desktopWidgets.gridSnap
              icon: "grid-3x3"
              tooltipText: I18n.tr("panels.desktop-widgets.edit-mode-grid-snap-scale-label")
              colorBg: Settings.data.desktopWidgets.gridSnapScale ? ShellColors.mPrimary : ShellColors.mSurfaceVariant
              colorFg: Settings.data.desktopWidgets.gridSnapScale ? ShellColors.mOnPrimary : ShellColors.mPrimary
              onClicked: Settings.data.desktopWidgets.gridSnapScale = !Settings.data.desktopWidgets.gridSnapScale
            }
          }
        }

        // Actions of the selected widget, next to it
        Rectangle {
          id: actions
          readonly property Item target: window.selectedItem
          readonly property real targetX: target ? window.stage.x + target.x * window.stage.scale : 0
          readonly property real targetY: target ? window.stage.y + target.y * window.stage.scale : 0
          readonly property real targetW: target ? target.width * window.stage.scale : 0
          readonly property real targetH: target ? target.height * window.stage.scale : 0

          visible: target !== null && !EditDesktopService.dragging
          width: actionsRow.implicitWidth + Style.marginS * 2
          height: actionsRow.implicitHeight + Style.marginXS * 2
          x: Math.max(Style.marginS, Math.min(targetX + (targetW - width) / 2, window.width - width - Style.marginS))
          y: targetY - height - Style.marginS >= Style.marginS ? targetY - height - Style.marginS : Math.min(targetY + targetH + Style.marginS, window.height - height - Style.marginS)
          radius: height / 2
          color: Qt.alpha(ShellColors.mSurface, 0.96)
          border.width: Style.borderS
          border.color: ShellColors.mPrimary
          z: 20

          RowLayout {
            id: actionsRow
            anchors.centerIn: parent
            spacing: Style.marginXS

            NIconButton {
              icon: "settings"
              tooltipText: I18n.tr("actions.widget-settings")
              onClicked: {
                const item = window.selectedItem;
                DesktopWidgetRegistry.openWidgetSettings(screenLoader.modelData, item.widgetIndex, item.widgetData.id, item.widgetData, space);
              }
            }
            NIconButton {
              icon: "restore"
              tooltipText: I18n.tr("common.reset")
              onClicked: window.selectedItem.handleContextMenuAction("reset")
            }
            NIconButton {
              icon: "stack-front"
              tooltipText: I18n.tr("actions.raise-to-top")
              onClicked: {
                window.selectedItem.handleContextMenuAction("raise-to-top");
                EditDesktopService.select(-1);
              }
            }
            NIconButton {
              icon: "stack-back"
              tooltipText: I18n.tr("actions.lower-to-bottom")
              onClicked: {
                window.selectedItem.handleContextMenuAction("lower-to-bottom");
                EditDesktopService.select(-1);
              }
            }
            NIconButton {
              icon: "trash"
              tooltipText: I18n.tr("common.delete")
              colorFg: ShellColors.mError
              onClicked: {
                window.selectedItem.removeWidget();
                EditDesktopService.select(-1);
              }
            }
          }
        }

        // The shelf slides up from the bottom edge
        EditShelf {
          id: shelf
          visible: window.isMain
          dragSpace: space
          screen: screenLoader.modelData
          x: EditDesktopService.cardPad
          width: window.width - 2 * EditDesktopService.cardPad
          height: EditDesktopService.shelfHeight - Style.marginM
          y: window.height - (EditDesktopService.shelfHeight) * window.progress

          onDone: DesktopWidgetRegistry.editMode = false

          onAddAtCenter: widgetId => EditDesktopService.addWidget(widgetId, window.width / 2, window.height / 2, window.width, window.height)
          onPullStarted: widgetId => {
            EditDesktopService.dragId = widgetId;
            EditDesktopService.select(-1);
          }
          onPullMoved: (x, y) => {
            EditDesktopService.dragX = x;
            EditDesktopService.dragY = y;
          }
          onPullEnded: (x, y) => {
            const id = EditDesktopService.dragId;
            EditDesktopService.cancelDrag();
            if (id === "")
              return;
            const at = Geometry.toDesktop(x, y, window.rect, window.width, window.height);
            if (at.inside)
              EditDesktopService.addWidget(id, at.x, at.y, window.width, window.height);
          }
          onPullCancelled: EditDesktopService.cancelDrag()
        }

        // What is being pulled, under the pointer, as big as it will be on the card
        Rectangle {
          readonly property var size: Geometry.ghostSize(200, 120, window.rect)
          visible: window.isMain && EditDesktopService.dragging
          width: size.width
          height: size.height
          x: EditDesktopService.dragX - width / 2
          y: EditDesktopService.dragY - height / 2
          radius: Style.radiusL * window.rect.s
          color: Qt.alpha(ShellColors.mPrimary, 0.35)
          border.width: 3
          border.color: ShellColors.mPrimary
          z: 100

          NText {
            anchors.centerIn: parent
            text: DesktopWidgetRegistry.getWidgetDisplayName(EditDesktopService.dragId)
            pointSize: Style.fontSizeS
            font.weight: Style.fontWeightBold
            color: ShellColors.mOnSurface
          }
        }
      }
    }
  }
}
