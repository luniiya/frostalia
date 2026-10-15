import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../../Helpers/BubbleLogic.js" as BubbleLogic
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI

PanelWindow {
  id: root

  required property string bubbleId
  readonly property string section: BubbleLogic.sectionId(bubbleId)
  readonly property var configuration: Settings.getBubble(screen?.name, section) || BubbleLogic.effective(null, BubbleService.defaults)
  readonly property var widgets: configuration.widgets
  readonly property bool vertical: BubbleLogic.isVertical(configuration.position)
  readonly property real flare: BubbleLogic.notchFlare(configuration)
  property int currentIndex: 0
  property int previousIndex: -1
  property real progress: 1
  property var vector: ({
                          x: 0,
                          y: -1
                        })
  property real measuredWidth: configuration.height
  property real measuredHeight: configuration.height

  // Read each toplevel's properties in the binding so fullscreen/output changes
  // update visibility even when the toplevel list itself hasn't changed.
  readonly property bool fullscreen: BubbleLogic.hasFullscreen(ToplevelManager.toplevels.values, screen?.name)
  readonly property bool hovered: hover.hovered
  readonly property bool panelOpen: PanelService.openedPanel?.screen === screen || BarService.popupOpen
  readonly property var placement: BubbleLogic.layout(Settings.data.bubbles.configurations, BubbleService.defaults, BubbleService.sizes, screen?.name, bubbleId, screen?.width || 1, screen?.height || 1)
  readonly property var body: BubbleLogic.bodyRect(configuration, width, height)

  readonly property bool shouldShow: BubbleLogic.shouldShow(Settings.data.bubbles.enabled, widgets.length, configuration.hideOnFullscreen, fullscreen)
  // Surface creation can synchronously re-evaluate child bindings. Defer it
  // until configuration/visibility bindings have finished settling.
  property bool windowVisible: false
  visible: windowVisible
  onShouldShowChanged: Qt.callLater(syncVisibility)
  color: "transparent"
  implicitWidth: placement.width
  implicitHeight: placement.height
  anchors.top: true
  anchors.left: true
  margins.left: placement.x
  margins.top: placement.y

  // Overlay is needed for the option to remain visible above fullscreen windows.
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.namespace: "frostalia-bubble-" + (screen?.name || "unknown") + "-" + bubbleId

  mask: Region {
    // Flare bounds can overlap a neighbor; keep its widget's input accessible.
    x: root.body.x
    y: root.body.y
    width: root.body.width
    height: root.body.height
  }

  function syncVisibility() {
    windowVisible = shouldShow;
  }

  function measure() {
    var size = BubbleLogic.contentSize(widgetRepeater.itemAt(currentIndex)?.widget, configuration);
    measuredWidth = size.width;
    measuredHeight = size.height;
    BubbleService.measure(screen?.name, bubbleId, measuredWidth, measuredHeight);
  }

  onCurrentIndexChanged: Qt.callLater(measure)

  function cycle(step) {
    if (widgets.length < 2 || transition.running || panelOpen)
      return;
    TooltipService.hide();
    previousIndex = currentIndex;
    currentIndex = BubbleLogic.nextIndex(currentIndex, widgets.length, step);
    vector = BubbleLogic.animationVector(configuration.transition, step);
    if (configuration.transition === "none" || Settings.data.general.animationDisabled || configuration.transitionDuration === 0) {
      previousIndex = -1;
      progress = 1;
    } else {
      progress = 0;
      transition.start();
    }
    if (cycleTimer.running)
      cycleTimer.restart();
  }

  function resetConfiguration() {
    transition.stop();
    previousIndex = -1;
    progress = 1;
    currentIndex = Math.min(currentIndex, Math.max(0, widgets.length - 1));
    if (cycleTimer.running)
      cycleTimer.restart();
    measure();
  }
  onConfigurationChanged: Qt.callLater(resetConfiguration)
  Component.onCompleted: {
    Qt.callLater(measure);
    Qt.callLater(syncVisibility);
  }
  Component.onDestruction: BubbleService.forget(screen?.name, bubbleId)

  Shape {
    id: background
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: Qt.alpha(BubbleLogic.backgroundColor(root.configuration, root.configuration.backgroundColorKey === "none" ? Color.mSurface : Color.resolveColorKey(root.configuration.backgroundColorKey)), BubbleLogic.backgroundOpacity(root.configuration))
      strokeColor: "transparent"
      strokeWidth: 0
      PathSvg {
        path: BubbleLogic.backgroundPath(background.width, background.height, root.configuration.style === "notch" ? root.flare : root.configuration.radius, root.configuration.style, root.configuration.position, BubbleLogic.cornerAttachment(root.placement, root.configuration.position, root.screen?.width || 1, root.screen?.height || 1))
      }
    }
  }

  Item {
    id: viewport
    readonly property var bubbleContext: ({
                                            section: root.section,
                                            oledMode: root.configuration.oledMode,
                                            position: root.configuration.position,
                                            x: root.placement.x,
                                            y: root.placement.y
                                          })
    anchors.fill: parent
    anchors.leftMargin: root.vertical ? 0 : root.configuration.padding + root.flare
    anchors.rightMargin: anchors.leftMargin
    anchors.topMargin: root.vertical ? root.configuration.padding + root.flare : 0
    anchors.bottomMargin: anchors.topMargin
    clip: true

    Repeater {
      id: widgetRepeater
      model: root.widgets.length

      delegate: Item {
        id: slot
        required property int index
        readonly property alias widget: widgetLoader
        readonly property bool current: index === root.currentIndex
        readonly property bool outgoing: index === root.previousIndex
        visible: current || outgoing
        width: viewport.width
        height: viewport.height
        x: root.vector.x * width * (current ? 1 - root.progress : -root.progress)
        y: root.vector.y * height * (current ? 1 - root.progress : -root.progress)
        opacity: root.configuration.transition === "fade" ? (current ? root.progress : 1 - root.progress) : 1

        BarWidgetLoader {
          id: widgetLoader
          anchors.centerIn: parent
          width: Math.min(implicitWidth, slot.width)
          height: Math.min(implicitHeight, slot.height)
          widgetId: root.widgets[slot.index]?.id || ""
          widgetScreen: root.screen
          widgetProps: ({
                          widgetId: widgetId,
                          section: root.section,
                          sectionWidgetIndex: slot.index,
                          sectionWidgetsCount: root.widgets.length
                        })
          registerInstance: slot.current && root.shouldShow
          preserveSizeWhenHidden: true
          onImplicitWidthChanged: Qt.callLater(root.measure)
          onImplicitHeightChanged: Qt.callLater(root.measure)
        }
      }
    }
  }

  HoverHandler {
    id: hover
  }

  // Passive to clicks; takes the wheel before child widgets only when cycling.
  BubbleWheelHandler {
    widgetCount: root.widgets.length
    onCycleRequested: step => root.cycle(step)
  }

  NumberAnimation {
    id: transition
    target: root
    property: "progress"
    from: 0
    to: 1
    duration: root.configuration.transitionDuration
    easing.type: Easing.OutCubic
    onFinished: root.previousIndex = -1
  }

  Timer {
    id: cycleTimer
    interval: root.configuration.cycleInterval * 1000
    repeat: true
    running: BubbleLogic.shouldAutoCycle(root.shouldShow, root.configuration.autoCycle, root.widgets.length, root.hovered, root.panelOpen)
    onTriggered: root.cycle(1)
  }
}
