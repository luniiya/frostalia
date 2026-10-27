import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Helpers/WallpaperRenderer.js" as WallpaperRenderer
import qs.Commons
import qs.Modules.WallpaperVisualizer
import qs.Services.Compositor
import qs.Services.UI

// One screen's wallpaper when the shell draws it (Settings > Wallpaper): a click-through
// window on the background layer showing WallpaperService.displayPathFor(screen), with a
// transition on every change. After SekaiPop's WallpaperLayer (github.com/Blapples/SekaiPop,
// GPL-3.0): the slot lifecycle and transitions are its, video and Edit Desktop are left out.
//
// Layers, bottom to top:
//   stage      everything the wallpaper draws, clipped to the screen; scale or move it as
//              a whole (Edit Desktop)
//   picture    the slots and the transition between them. With parallax it is zoomed
//              larger than the stage and slides with the workspace (Helpers/WallpaperRenderer.js)
//   overlays   effects over the picture go after `picture` inside `stage`
//
// Every change makes a new WallpaperSlot for the incoming picture and destroy()s the
// outgoing one once it has been blended out, rather than keeping two Images and swapping
// their sources: fast changes would otherwise leave GPU textures behind.
PanelWindow {
  id: win

  readonly property string screenName: screen ? screen.name : ""

  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "frostalia-wallpaper-" + (screen?.name || "unknown")
  // Shown until the first picture has decoded
  color: "transparent"
  // Clicks go through, as they did to the wallpaper daemon's surface
  mask: Region {}

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  readonly property var prefs: Settings.data.wallpaperRenderer

  // The pre-scaled file for this screen and the one the current slot was made for
  readonly property string wanted: WallpaperService.displayPathFor(screenName)
  property string shown: ""

  // 0 at the start of a change, 1 once it has finished (only blendAnim writes it)
  property real progress: 1.0
  // The style this change plays and its rolled parameters, fixed when the change starts
  // so a setting changed mid-blend can't swap shaders under it
  property string activeStyle: "fade"
  property var activeParams: WallpaperRenderer.classicParams()

  property Item previousSlot: null
  property Item currentSlot: null
  readonly property bool transitioning: previousSlot !== null

  // Decode at the device-pixel size the cache cut the picture to; without ImageMagick the
  // original is decoded at that size instead of in full
  readonly property size decodeSize: {
    const s = WallpaperRenderer.cacheSize(width, height, screen ? screen.devicePixelRatio : 1, zoom);
    return Qt.size(s.width, s.height);
  }

  // Parallax: how far `picture` is zoomed in, and where it sits for this screen's workspace
  readonly property real zoom: WallpaperService.zoom
  property int workspace: 0
  readonly property real slide: WallpaperRenderer.parallaxFraction(workspace, prefs.parallaxWorkspaces)

  function updateWorkspace() {
    const list = [];
    for (let i = 0; i < CompositorService.workspaces.count; i++)
      list.push(CompositorService.workspaces.get(i));
    workspace = WallpaperRenderer.activeWorkspace(list, screenName);
  }

  Connections {
    target: CompositorService
    enabled: win.zoom > 1
    function onWorkspaceChanged() {
      win.updateWorkspace();
    }
    function onWorkspacesChanged() {
      win.updateWorkspace();
    }
  }
  onZoomChanged: updateWorkspace()

  // Band colours of the sekai transitions, eased so a theme generated from the new
  // wallpaper mid-transition doesn't make them jump
  readonly property var bandColors: WallpaperRenderer.transitionColors(prefs.colors, ShellColors.mPrimary.toString(), ShellColors.mSecondary.toString(), ShellColors.mTertiary.toString())
  property color colorWhite: bandColors.white
  property color colorPink: bandColors.pink
  property color colorCyan: bandColors.cyan
  property color colorGreen: bandColors.green
  Behavior on colorWhite {
    ColorAnimation {
      duration: 450
    }
  }
  Behavior on colorPink {
    ColorAnimation {
      duration: 450
    }
  }
  Behavior on colorCyan {
    ColorAnimation {
      duration: 450
    }
  }
  Behavior on colorGreen {
    ColorAnimation {
      duration: 450
    }
  }

  Component {
    id: slotComponent
    WallpaperSlot {}
  }

  function createSlot(file) {
    // Into `picture`, not the window: an object created on a window isn't in its scene.
    // The decode size goes in with the source so the picture is decoded once.
    const slot = slotComponent.createObject(picture, {
                                              "sourceSize": win.decodeSize,
                                              "source": file ? "file://" + file : ""
                                            });
    slot.statusChanged.connect(() => {
      const done = slot.status === Image.Ready || slot.status === Image.Error;
      if (done && slot === win.currentSlot)
        win.slotReady();
    });
    bindRole(slot);
    return slot;
  }

  // Drawn by itself at rest; sampled by the transition (and hidden) while one runs. With
  // no transition the outgoing picture stays up until the incoming one has decoded.
  function bindRole(slot) {
    slot.visible = Qt.binding(() => (slot === win.currentSlot && win.previousSlot === null) || (slot === win.previousSlot && win.activeStyle === "none"));
    slot.layer.enabled = Qt.binding(() => win.previousSlot !== null && (slot === win.previousSlot || slot === win.currentSlot));
  }

  function swapTo(file) {
    if (currentSlot && currentSlot.status !== Image.Ready) {
      // Changed again before the last picture decoded, so it never showed: drop it and
      // keep blending out of what is actually on screen
      currentSlot.destroy();
      currentSlot = null;
      currentSlot = createSlot(file);
      return;
    }
    if (previousSlot)
      previousSlot.destroy();
    previousSlot = currentSlot;
    currentSlot = createSlot(file);
  }

  function show(file) {
    if (file === "" || file === shown)
      return;
    shown = file;
    activeStyle = WallpaperService.styleForSwitch();
    activeParams = WallpaperRenderer.classicParams();
    blendAnim.stop();
    warmup.stop();
    progress = 0.0;
    swapTo(file);
    // The blend starts from slotReady() once the incoming picture has decoded; until then
    // progress 0 shows the outgoing one as it is
    readyTimeout.restart();
  }

  function slotReady() {
    readyTimeout.stop();
    // One beat so the new texture's first upload lands while progress is still 0
    warmup.restart();
  }

  function finishTransition() {
    if (previousSlot) {
      previousSlot.destroy();
      previousSlot = null;
    }
    progress = 1.0;
  }

  onWantedChanged: show(wanted)
  Component.onCompleted: {
    updateWorkspace();
    if (wanted !== "") {
      shown = wanted;
      currentSlot = createSlot(wanted);
    }
  }

  // A file that never reports (corrupt, unreadable) mustn't hold the change forever
  Timer {
    id: readyTimeout
    interval: 5000
    onTriggered: win.slotReady()
  }

  Timer {
    id: warmup
    interval: 50
    onTriggered: {
      // The first picture has nothing to blend from
      if (!win.previousSlot)
        return;
      if (blendAnim.duration > 0)
        blendAnim.restart();
      else
        win.finishTransition();
    }
  }

  NumberAnimation {
    id: blendAnim
    target: win
    property: "progress"
    from: 0.0
    to: 1.0
    duration: WallpaperRenderer.durationFor(win.activeStyle, win.prefs.duration)
    easing.type: WallpaperRenderer.linearFor(win.activeStyle) ? Easing.Linear : Easing.InOutQuad
    onFinished: win.finishTransition()
  }

  Item {
    id: stage
    anchors.fill: parent
    clip: win.zoom > 1

    Item {
      id: picture
      width: stage.width * win.zoom
      height: stage.height * win.zoom
      x: WallpaperRenderer.parallaxShift(win.slide, stage.width, win.zoom)
      y: WallpaperRenderer.parallaxShift(0.5, stage.height, win.zoom)

      Behavior on x {
        NumberAnimation {
          duration: Math.max(0, win.prefs.parallaxDuration)
          easing.type: Easing.OutCubic
        }
      }

      Loader {
        anchors.fill: parent
        z: 1
        active: win.transitioning && win.activeStyle !== "none"
        sourceComponent: WallpaperRenderer.familyFor(win.activeStyle) === "classic" ? classicBlend : sekaiBlend
      }
    }

    // The audio waves, over the picture but not zoomed or slid with it
    Loader {
      anchors.fill: parent
      active: Settings.data.wallpaperVisualizer.enabled
      sourceComponent: ScreenWaves {
        screenName: win.screenName
        devicePixelRatio: win.screen?.devicePixelRatio ?? 1
      }
    }
  }

  // SekaiPop's transitions. Properties are matched to the shader's uniforms by name and
  // the ones a shader doesn't have are ignored, so one effect carries what all of them need.
  Component {
    id: sekaiBlend
    ShaderEffect {
      property var source1: win.previousSlot
      property var source2: win.currentSlot
      property real progress: win.progress
      property real aspect: height > 0 ? width / height : 1.0
      property color colorWhite: win.colorWhite
      property color colorPink: win.colorPink
      property color colorCyan: win.colorCyan
      property color colorGreen: win.colorGreen
      property color accentColor: win.colorCyan
      property vector2d center: Qt.vector2d(0.5, 0.5)
      property real colorIntensity: 1.0
      // ring
      property int transitionStyle: WallpaperRenderer.ringVariantIndex(win.prefs.ringVariant)
      property real distortion: 1.0
      property real speed: 1.0
      property real ringWidth: 0.44
      // star
      property real thickness: 0.2
      property real pointLength: 3.0
      property real curvature: 1.0
      property real elastic: 1.0
      property real spin: 0.5
      // blocks
      property vector2d direction: Qt.vector2d(-1, -1)
      property real bandThickness: 0.2
      property real blockSize: 0.34
      property real stagger: 1.0

      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/" + WallpaperRenderer.shaderFor(win.activeStyle) + ".frag.qsb")
    }
  }

  // Noctalia's transitions. The slots are already cut to the screen, so they are sampled
  // as they are (fill mode 3, stretch).
  Component {
    id: classicBlend
    ShaderEffect {
      property var source1: win.previousSlot
      property var source2: win.currentSlot
      property real progress: win.progress
      property real aspectRatio: height > 0 ? width / height : 1.0
      property real smoothness: 0.5
      property real direction: win.activeParams.direction
      property real centerX: win.activeParams.centerX
      property real centerY: win.activeParams.centerY
      property real angle: win.activeParams.angle
      property real stripeCount: 12.0
      property real cellSize: 0.04
      property real maxBlockSize: 64.0
      property real fillMode: 3.0
      property real imageWidth1: width
      property real imageHeight1: height
      property real imageWidth2: width
      property real imageHeight2: height
      property real screenWidth: width
      property real screenHeight: height
      property vector4d fillColor: Qt.vector4d(0, 0, 0, 1)
      property real isSolid1: 0.0
      property real isSolid2: 0.0
      property vector4d solidColor1: Qt.vector4d(0, 0, 0, 1)
      property vector4d solidColor2: Qt.vector4d(0, 0, 0, 1)

      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/" + WallpaperRenderer.shaderFor(win.activeStyle) + ".frag.qsb")
    }
  }
}
