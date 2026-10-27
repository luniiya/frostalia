import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Helpers/EditDesktopGeometry.js" as Geometry
import "../../Helpers/WallpaperVisualizer.js" as WallpaperVisualizer
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.UI
import qs.Widgets

// The shelf of everything that can be put on the desktop, in two pages picked on the left:
// widgets (framed tiles with a live preview; click a tile to add it, or pull it up onto the
// card) and effects drawn on the wallpaper (hover a tile to preview it on the card; the gear on
// the waves tile opens their settings above the shelf). Done closes the editor.
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

  // 0: widgets, 1: effects
  property int page: 0
  readonly property var visualizer: Settings.data.wallpaperVisualizer
  // Effect tile under the pointer, and whether the wave settings are open; the card previews them
  property string hoveredEffect: ""
  property bool settingsOpen: false
  readonly property string previewEffect: WallpaperVisualizer.previewEffect(hoveredEffect, settingsOpen)
  readonly property string depthStatus: WallpaperVisualizer.depthStatus(WallpaperCutoutService.results, WallpaperService.getWallpaper(screen?.name ?? ""), visualizer.depth)

  color: ShellColors.mSurface
  radius: Style.radiusL
  border.width: Style.borderS
  border.color: Qt.alpha(ShellColors.mOutline, 0.4)

  onPageChanged: settingsOpen = false
  onVisibleChanged: settingsOpen = false

  NStyleCard {}

  RowLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginL

    // Pages: widgets to place, and effects drawn on the wallpaper
    ColumnLayout {
      // Fixed width: the buttons fill it, which would otherwise let the rail take the whole row
      Layout.fillWidth: false
      Layout.preferredWidth: Math.round(170 * Style.uiScaleRatio)
      Layout.maximumWidth: Layout.preferredWidth
      Layout.fillHeight: true
      spacing: Style.marginS

      NText {
        Layout.bottomMargin: Style.marginXS
        text: I18n.tr("panels.desktop-widgets.edit-title")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: root.ink
      }

      Repeater {
        model: [
          {
            "icon": "layout-grid",
            "label": "panels.desktop-widgets.edit-tab-widgets"
          },
          {
            "icon": "sparkles",
            "label": "panels.desktop-widgets.edit-tab-effects"
          }
        ]

        delegate: Rectangle {
          id: railButton
          required property var modelData
          required property int index
          readonly property bool current: root.page === index

          Layout.fillWidth: true
          Layout.preferredHeight: Math.round(40 * Style.uiScaleRatio)
          radius: height / 2
          color: current ? ShellColors.mPrimary : railArea.containsMouse ? ShellColors.mHover : "transparent"

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.marginM
            anchors.rightMargin: Style.marginM
            spacing: Style.marginS

            NIcon {
              icon: railButton.modelData.icon
              pointSize: Style.fontSizeL
              color: railButton.current ? ShellColors.mOnPrimary : root.ink
            }
            NText {
              Layout.fillWidth: true
              text: I18n.tr(railButton.modelData.label)
              pointSize: Style.fontSizeM
              font.weight: Style.fontWeightSemiBold
              color: railButton.current ? ShellColors.mOnPrimary : root.ink
              elide: Text.ElideRight
            }
          }

          MouseArea {
            id: railArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.page = railButton.index
          }
        }
      }

      Item {
        Layout.fillHeight: true
      }
    }

    Rectangle {
      Layout.preferredWidth: 2
      Layout.fillHeight: true
      Layout.topMargin: Style.marginS
      Layout.bottomMargin: Style.marginS
      color: Qt.alpha(ShellColors.mOutline, 0.3)
    }

    StackLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      currentIndex: root.page

      ListView {
        id: list
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

      // Effects: the wallpaper visualizer, as tiles that toggle or cycle on click
      Row {
        id: effectRow
        spacing: Style.marginXL

        EffectTile {
          id: wavesTile
          effectId: "waves"
          configurable: true
          icon: "wave-sine"
          label: I18n.tr("panels.audio.wallpaper-visualizer-enabled-label")
          active: root.visualizer.enabled
          value: active ? I18n.tr("panels.desktop-widgets.effect-on") : I18n.tr("panels.desktop-widgets.effect-off")
          onClicked: root.visualizer.enabled = !root.visualizer.enabled
        }

        EffectTile {
          effectId: "depth"
          icon: "layers-subtract"
          label: I18n.tr("panels.audio.wallpaper-visualizer-depth-label")
          available: root.visualizer.enabled
          active: root.visualizer.depth
          value: I18n.tr(WallpaperVisualizer.depthLabelKey(root.depthStatus))
          onClicked: root.visualizer.depth = !root.visualizer.depth
        }

        EffectTile {
          effectId: "edges"
          icon: "border-sides"
          label: I18n.tr("panels.audio.wallpaper-visualizer-edges-label")
          available: root.visualizer.enabled
          active: true
          cycles: true
          value: I18n.tr(WallpaperVisualizer.edgeLabelKey(root.visualizer.edges))
          onClicked: root.visualizer.edges = WallpaperVisualizer.nextEdges(root.visualizer.edges)
        }

        EffectTile {
          icon: "settings"
          label: I18n.tr("panels.desktop-widgets.effect-more")
          active: false
          badge: false
          value: I18n.tr("common.visualizer")
          onClicked: {
            root.done();
            SettingsPanelService.openToTab(SettingsPanel.Tab.Audio, 3, root.screen);
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

  // Wave settings, above the shelf over the waves tile; every change shows on the card right away
  Rectangle {
    id: waveSettings
    // Drawn by the shelf's parent: styles like keycap render the shelf into a layer for its
    // shadow, and a layer clips whatever sticks out of the shelf
    parent: root.parent
    z: 30
    visible: root.visible && root.settingsOpen
    // Mapped again on each open, once the tiles are laid out
    readonly property real anchorX: root.settingsOpen ? wavesTile.mapToItem(root, 0, 0).x : 0

    width: Math.round(640 * Style.uiScaleRatio)
    height: settingsColumn.implicitHeight + Style.marginL * 2
    x: root.x + Math.max(0, Math.min(anchorX, root.width - width))
    y: root.y - height - Style.marginM
    radius: Style.radiusL
    // Opaque like the shelf: the sliders sit over the card, whose wallpaper would show through
    color: ShellColors.mSurface
    border.width: Style.borderS
    border.color: ShellColors.mPrimary

    NStyleCard {}

    // Keeps clicks in the gaps from reaching the card below
    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      id: settingsColumn
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NIcon {
          icon: "wave-sine"
          pointSize: Style.fontSizeL
          color: ShellColors.mPrimary
        }
        NText {
          Layout.fillWidth: true
          text: I18n.tr("panels.desktop-widgets.effect-wave-settings")
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightBold
          color: root.ink
        }
        NIconButton {
          icon: "external-link"
          tooltipText: I18n.tr("panels.desktop-widgets.effect-more")
          onClicked: {
            root.done();
            SettingsPanelService.openToTab(SettingsPanel.Tab.Audio, 3, root.screen);
          }
        }
        NIconButton {
          icon: "x"
          tooltipText: I18n.tr("common.close")
          onClicked: root.settingsOpen = false
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Style.marginXL
        rowSpacing: Style.marginM

        WaveSlider {
          key: "height"
          label: I18n.tr("panels.audio.wallpaper-visualizer-height-label")
          range: WallpaperVisualizer.heightRange
        }
        WaveSlider {
          key: "opacity"
          label: I18n.tr("panels.audio.wallpaper-visualizer-opacity-label")
          range: WallpaperVisualizer.opacityRange
        }
        WaveSlider {
          key: "whiteness"
          label: I18n.tr("panels.audio.wallpaper-visualizer-whiteness-label")
          range: WallpaperVisualizer.whitenessRange
        }
        WaveSlider {
          key: "rim"
          label: I18n.tr("panels.audio.wallpaper-visualizer-rim-label")
          range: WallpaperVisualizer.rimRange
        }
        WaveSlider {
          key: "backWave"
          label: I18n.tr("panels.audio.wallpaper-visualizer-back-wave-label")
          range: WallpaperVisualizer.backWaveRange
        }
        WaveSlider {
          key: "softness"
          label: I18n.tr("panels.audio.wallpaper-visualizer-softness-label")
          range: WallpaperVisualizer.softnessRange
        }

        NColorChoice {
          Layout.fillWidth: true
          Layout.columnSpan: 2
          label: I18n.tr("panels.audio.wallpaper-visualizer-color-label")
          description: ""
          currentKey: root.visualizer.color
          defaultValue: Settings.getDefaultValue("wallpaperVisualizer.color")
          onSelected: key => root.visualizer.color = key
        }
      }
    }
  }

  // A slider for one wave setting, shown as a percentage
  component WaveSlider: NValueSlider {
    property string key
    property var range: [0, 1]

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    from: range[0]
    to: range[1]
    stepSize: 0.01
    showReset: true
    value: root.visualizer[key]
    defaultValue: Settings.getDefaultValue("wallpaperVisualizer." + key)
    onMoved: value => root.visualizer[key] = value
    text: Math.round(root.visualizer[key] * 100) + "%"
  }

  // An effect tile, framed like the widget tiles: icon and current value inside, name below,
  // and an on/off badge (or a cycle mark) in the corner
  component EffectTile: Item {
    id: effect
    property string icon
    property string label
    property string value
    property bool active
    property bool cycles: false
    property bool badge: true
    // Previewed on the card while hovered, when set
    property string effectId: ""
    // Has a gear that opens the wave settings
    property bool configurable: false
    // Clickable; an unavailable tile is dimmed but still previews
    property bool available: true
    signal clicked

    readonly property bool hovered: effectArea.containsMouse || gearArea.containsMouse
    readonly property bool lit: hovered && available

    width: Math.round(210 * Style.uiScaleRatio)
    height: parent ? parent.height : 0
    opacity: available ? 1 : 0.45

    onHoveredChanged: {
      if (!effectId)
        return;
      if (hovered)
        root.hoveredEffect = effectId;
      else if (root.hoveredEffect === effectId)
        root.hoveredEffect = "";
    }

    Rectangle {
      id: effectFrame
      anchors.fill: parent
      anchors.margins: 6
      anchors.bottomMargin: Style.marginXL
      radius: Style.radiusL
      // Opaque: keycap's shadow is a shifted copy of the tile, and it would show through the icon and label
      color: effect.lit ? Qt.tint(ShellColors.mSurfaceVariant, ShellColors.mHover) : effect.active && effect.badge && !effect.cycles ? Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mPrimary, 0.16)) : ShellColors.mSurfaceVariant
      border.width: effect.lit ? 2 : 0
      border.color: ShellColors.mPrimary

      NStyleCard {
        hovered: effectArea.containsMouse
        pressed: effectArea.pressed
      }

      Behavior on color {
        ColorAnimation {
          duration: Style.animationFast
        }
      }

      ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - Style.marginL * 2
        spacing: Style.marginXS

        NIcon {
          Layout.alignment: Qt.AlignHCenter
          icon: effect.icon
          pointSize: Style.fontSizeXXL
          color: effect.active && !effect.cycles ? ShellColors.mPrimary : root.ink
        }
        NText {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: effect.value
          pointSize: Style.fontSizeS
          color: ShellColors.mOnSurfaceVariant
          elide: Text.ElideRight
        }
      }
    }

    NText {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: effectFrame.bottom
      anchors.topMargin: Style.marginXS
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: effect.label
      pointSize: Style.fontSizeS
      font.weight: Style.fontWeightSemiBold
      color: effect.lit ? ShellColors.mPrimary : ShellColors.mOnSurface
      elide: Text.ElideRight
    }

    Rectangle {
      visible: effect.badge
      anchors.right: effectFrame.right
      anchors.top: effectFrame.top
      anchors.margins: Style.marginS
      width: Math.round(24 * Style.uiScaleRatio)
      height: width
      radius: width / 2
      color: effect.cycles || effect.active ? ShellColors.mPrimary : "transparent"
      border.width: effect.cycles || effect.active ? 0 : Style.borderM
      border.color: ShellColors.mOutline

      NIcon {
        anchors.centerIn: parent
        visible: effect.cycles || effect.active
        icon: effect.cycles ? "refresh" : "check"
        pointSize: Style.fontSizeS
        color: ShellColors.mOnPrimary
      }
    }

    MouseArea {
      id: effectArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: effect.available ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: {
        if (effect.available)
          effect.clicked();
      }
    }

    // Gear in the top-left corner: opens or closes the wave settings
    Rectangle {
      visible: effect.configurable
      anchors.left: effectFrame.left
      anchors.top: effectFrame.top
      anchors.margins: Style.marginS
      width: Math.round(28 * Style.uiScaleRatio)
      height: width
      radius: width / 2
      color: root.settingsOpen ? ShellColors.mPrimary : gearArea.containsMouse ? ShellColors.mHover : ShellColors.mSurface
      border.width: root.settingsOpen ? 0 : Style.borderS
      border.color: ShellColors.mOutline

      NIcon {
        anchors.centerIn: parent
        icon: "adjustments-horizontal"
        pointSize: Style.fontSizeS
        color: root.settingsOpen ? ShellColors.mOnPrimary : root.ink
      }

      MouseArea {
        id: gearArea
        anchors.fill: parent
        enabled: effect.configurable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.settingsOpen = !root.settingsOpen
      }
    }
  }
}
