import QtQuick
import QtQuick.Effects
import Quickshell
import "../../Helpers/DesktopWidgetEdit.js" as WidgetEdit
import "../../Helpers/EditDesktopGeometry.js" as EditGeometry
import qs.Commons
import qs.Services.Frostalia
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property ShellScreen screen
  property var widgetData: null
  property int widgetIndex: -1

  // Only the instances shown on the Edit Desktop card can be edited
  property bool editing: false
  readonly property bool selected: editing && widgetIndex >= 0 && EditDesktopService.selectedIndex === widgetIndex

  property real defaultX: 100
  property real defaultY: 100

  default property alias content: contentContainer.data

  readonly property bool isDragging: internal.isDragging
  readonly property bool isScaling: internal.isScaling || internal.isResizing
  readonly property bool isResizing: internal.isResizing

  // All Desktop widgets have these settings, but fallback just in case
  readonly property var _metadata: widgetData?.id ? DesktopWidgetRegistry.widgetMetadata[widgetData.id] : null
  property bool showBackground: widgetData.showBackground !== undefined ? widgetData.showBackground : (_metadata?.showBackground ?? true)
  property bool roundedCorners: widgetData.roundedCorners !== undefined ? widgetData.roundedCorners : (_metadata?.roundedCorners ?? true)

  property real widgetScale: 1.0
  property bool horizontalResizable: false
  property bool verticalResizable: false
  property real widgetWidthScale: 1.0
  property real widgetHeightScale: 1.0
  property real minimumWidgetWidth: Math.min(implicitWidth, 96 * widgetScale)
  property real minimumWidgetHeight: Math.min(implicitHeight, 48 * widgetScale)
  // With grid snap on a widget covers whole grid cells, so edges of widgets on the same grid lines line up
  readonly property bool gridSized: Settings.data.desktopWidgets.gridSnap
  width: gridSized ? WidgetEdit.gridLength(Math.round(implicitWidth * (horizontalResizable ? widgetWidthScale : 1)), gridSize) : Math.round(implicitWidth * (horizontalResizable ? widgetWidthScale : 1))
  height: gridSized ? WidgetEdit.gridLength(Math.round(implicitHeight * (verticalResizable ? widgetHeightScale : 1)), gridSize) : Math.round(implicitHeight * (verticalResizable ? widgetHeightScale : 1))
  readonly property real backgroundRadius: container.radius

  // A per-widget setting, falling back to the registry default
  function widgetSetting(key) {
    if (widgetData && widgetData[key] !== undefined)
      return widgetData[key];
    return _metadata ? _metadata[key] : undefined;
  }
  property real minScale: 0.5
  property real maxScale: 5.0

  readonly property real scaleSensitivity: 0.0015
  readonly property real scaleUpdateThreshold: 0.015
  readonly property real cornerScaleSensitivity: 0.0003  // Much lower sensitivity for corner handles

  // One grid for the overlay and for snapping, see DesktopWidgetEdit.js
  readonly property int gridSize: WidgetEdit.gridSize(screen ? screen.width : 0, screen ? screen.height : 0)

  QtObject {
    id: internal
    property bool isDragging: false
    property bool isScaling: false
    property bool isResizing: false
    property real initialX: 0
    property real initialY: 0
    property real initialWidthScale: 1
    property real initialHeightScale: 1
    property real dragOffsetX: 0
    property real dragOffsetY: 0
    property real baseX: (root.widgetData && root.widgetData.x !== undefined) ? root.widgetData.x : root.defaultX
    property real baseY: (root.widgetData && root.widgetData.y !== undefined) ? root.widgetData.y : root.defaultY
    property real initialWidth: 0
    property real initialHeight: 0
    property point initialMousePos: Qt.point(0, 0)
    property real initialScale: 1.0
    property real lastScale: 1.0
    // Locks operation type to prevent switching between drag/scale mid-operation
    property string operationType: ""  // "drag" or "scale" or ""
  }

  // Distance (in desktop pixels) at which a dragged widget snaps to another widget
  readonly property real snapThreshold: 8

  // The other widgets of this layer, as rectangles
  function siblingRects() {
    var rects = [];
    if (!root.parent)
      return rects;
    var kids = root.parent.children;
    for (var i = 0; i < kids.length; i++) {
      var k = kids[i];
      if (k !== root && k.widgetData !== undefined && k.visible && k.width > 0 && k.height > 0)
        rects.push({
                     "x": k.x,
                     "y": k.y,
                     "width": k.width,
                     "height": k.height
                   });
    }
    return rects;
  }

  function clearGuides() {
    if (root.parent && root.parent.guides !== undefined)
      root.parent.guides = [];
  }

  function snapToGrid(coord) {
    if (!Settings.data.desktopWidgets.gridSnap) {
      return coord;
    }
    return Math.round(coord / root.gridSize) * root.gridSize;
  }

  function snapScaleToGrid(scale, precise) {
    const baseWidth = internal.initialWidth > 0 && internal.initialScale > 0 ? internal.initialWidth / internal.initialScale : 0;
    const grid = Settings.data.desktopWidgets.gridSnap && Settings.data.desktopWidgets.gridSnapScale ? root.gridSize : 0;
    return WidgetEdit.snappedScale(scale, minScale, maxScale, precise, baseWidth, grid);
  }

  function updateWidgetData(properties) {
    if (widgetIndex < 0 || !screen || !screen.name) {
      return;
    }
    DesktopWidgetRegistry.updateWidgetData(screen.name, widgetIndex, properties);
  }

  function removeWidget() {
    if (widgetIndex < 0 || !screen || !screen.name) {
      return;
    }

    var monitorWidgets = Settings.data.desktopWidgets.monitorWidgets || [];
    var newMonitorWidgets = monitorWidgets.slice();

    for (var i = 0; i < newMonitorWidgets.length; i++) {
      if (newMonitorWidgets[i].name === screen.name) {
        var widgets = (newMonitorWidgets[i].widgets || []).slice();
        if (widgetIndex >= 0 && widgetIndex < widgets.length) {
          widgets.splice(widgetIndex, 1);
          newMonitorWidgets[i] = Object.assign({}, newMonitorWidgets[i], {
                                                 "widgets": widgets
                                               });
          Settings.data.desktopWidgets.monitorWidgets = newMonitorWidgets;
        }
        break;
      }
    }
  }

  function raiseToTop() {
    if (widgetIndex < 0 || !screen || !screen.name) {
      return;
    }

    var monitorWidgets = Settings.data.desktopWidgets.monitorWidgets || [];
    var newMonitorWidgets = monitorWidgets.slice();

    for (var i = 0; i < newMonitorWidgets.length; i++) {
      if (newMonitorWidgets[i].name === screen.name) {
        var widgets = (newMonitorWidgets[i].widgets || []).slice();
        if (widgetIndex < widgets.length && widgetIndex < widgets.length - 1) {
          var widget = widgets.splice(widgetIndex, 1)[0];
          widgets.push(widget);
          newMonitorWidgets[i] = Object.assign({}, newMonitorWidgets[i], {
                                                 "widgets": widgets
                                               });
          Settings.data.desktopWidgets.monitorWidgets = newMonitorWidgets;
        }
        break;
      }
    }
  }

  function lowerToBottom() {
    if (widgetIndex < 0 || !screen || !screen.name) {
      return;
    }

    var monitorWidgets = Settings.data.desktopWidgets.monitorWidgets || [];
    var newMonitorWidgets = monitorWidgets.slice();

    for (var i = 0; i < newMonitorWidgets.length; i++) {
      if (newMonitorWidgets[i].name === screen.name) {
        var widgets = (newMonitorWidgets[i].widgets || []).slice();
        if (widgetIndex < widgets.length && widgetIndex > 0) {
          var widget = widgets.splice(widgetIndex, 1)[0];
          widgets.unshift(widget);
          newMonitorWidgets[i] = Object.assign({}, newMonitorWidgets[i], {
                                                 "widgets": widgets
                                               });
          Settings.data.desktopWidgets.monitorWidgets = newMonitorWidgets;
        }
        break;
      }
    }
  }

  function openWidgetSettings() {
    DesktopWidgetRegistry.openWidgetSettings(screen, widgetIndex, widgetData.id, widgetData);
  }

  function handleContextMenuAction(action) {
    if (action === "widget-settings") {
      // Don't close - openWidgetSettings will use the popup window for the dialog
      root.openWidgetSettings();
      return true; // Signal that we're handling close ourselves
    } else if (action === "reset") {
      // Reset scale and position to defaults
      root.widgetScale = 1.0;
      root.widgetWidthScale = 1.0;
      root.widgetHeightScale = 1.0;
      internal.baseX = root.defaultX;
      internal.baseY = root.defaultY;
      root.updateWidgetData({
                              "scale": 1.0,
                              "widthScale": 1.0,
                              "heightScale": 1.0,
                              "x": Math.round(root.defaultX),
                              "y": Math.round(root.defaultY)
                            });
      return false;
    } else if (action === "raise-to-top") {
      root.raiseToTop();
      return false;
    } else if (action === "lower-to-bottom") {
      root.lowerToBottom();
      return false;
    } else if (action === "delete") {
      root.removeWidget();
      return false; // Let caller close the popup
    }
    return false;
  }

  x: Math.round(internal.isDragging ? internal.dragOffsetX : internal.baseX)
  y: Math.round(internal.isDragging ? internal.dragOffsetY : internal.baseY)

  // Note: We no longer use transform-based scaling (scale property)
  // Instead, child widgets multiply their dimensions by widgetScale
  // This prevents blurry text at fractional scale values

  Component.onCompleted: {
    root.widgetWidthScale = widgetData?.widthScale ?? 1;
    root.widgetHeightScale = widgetData?.heightScale ?? 1;
    // Initialize scale from widgetData when component is first created
    if (widgetData && widgetData.scale !== undefined) {
      widgetScale = widgetData.scale;
    }
  }

  onWidgetDataChanged: {
    if (!internal.isDragging && !internal.isScaling && !internal.isResizing) {
      root.widgetWidthScale = widgetData?.widthScale ?? 1;
      root.widgetHeightScale = widgetData?.heightScale ?? 1;
      internal.baseX = (widgetData && widgetData.x !== undefined) ? widgetData.x : defaultX;
      internal.baseY = (widgetData && widgetData.y !== undefined) ? widgetData.y : defaultY;
      if (widgetData && widgetData.scale !== undefined) {
        widgetScale = widgetData.scale;
      } else if (widgetData) {
        // If widgetData exists but scale is not set, default to 1.0
        widgetScale = 1.0;
      }
    }
  }

  Rectangle {
    id: decorationRect
    anchors.fill: parent
    anchors.margins: -outlineMargin
    color: root.editing ? Qt.rgba(ShellColors.mPrimary.r, ShellColors.mPrimary.g, ShellColors.mPrimary.b, root.selected ? 0.18 : 0.06) : "transparent"
    border.color: (root.editing || internal.isDragging) ? (internal.isDragging ? ShellColors.mOutline : (root.selected ? ShellColors.mPrimary : Qt.alpha(ShellColors.mPrimary, 0.45))) : "transparent"
    border.width: root.editing ? (root.selected ? 3 : 2) : 0
    radius: Math.min(Math.round(Style.radiusL * root.widgetScale), Style.radiusL, width / 2, height / 2)
    z: -1
  }

  Rectangle {
    id: container
    anchors.fill: parent
    radius: root.roundedCorners ? Math.min(Math.round(Style.radiusL * root.widgetScale), Style.radiusL, width / 2, height / 2) : 0
    // Not frosted: desktop widgets get no compositor blur, and a translucent
    // background would show its own drop shadow through.
    color: Qt.alpha(ShellColors.mSurface, Settings.data.ui.panelBackgroundOpacity)
    border {
      width: 1
      color: Qt.alpha(ShellColors.mOutline, 0.12)
    }
    clip: true
    visible: root.showBackground

    layer.enabled: Settings.data.general.enableShadows && !internal.isDragging && root.showBackground
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowBlur: Style.shadowBlur * 1.5
      shadowOpacity: Style.shadowOpacity * 0.6
      shadowColor: "black"
      shadowHorizontalOffset: Settings.data.general.shadowOffsetX
      shadowVerticalOffset: Settings.data.general.shadowOffsetY
      blurMax: Style.shadowBlurMax
    }
  }

  Item {
    id: contentContainer
    anchors.fill: parent
    z: 1
    clip: true
  }

  Rectangle {
    id: sizeFeedback
    visible: root.editing && (internal.isScaling || internal.isResizing || dragArea.containsMouse)
    z: 3000
    width: sizeLabel.implicitWidth + Style.margin2M
    height: sizeLabel.implicitHeight + Style.margin2S
    radius: Style.radiusS
    color: ShellColors.mPrimary
    readonly property var placement: WidgetEdit.feedbackPosition(root.x, root.y, root.width, root.height, width, height, root.screen ? root.screen.width : 1920, root.screen ? root.screen.height : 1080, Style.marginS)
    x: placement.x
    y: placement.y

    NText {
      id: sizeLabel
      anchors.centerIn: parent
      pointSize: Style.fontSizeS
      color: ShellColors.mOnPrimary
      text: I18n.tr("panels.desktop-widgets.size-feedback", {
                      "widthScale": WidgetEdit.scaleText(root.widgetScale * (root.horizontalResizable ? root.widgetWidthScale : 1)),
                      "heightScale": WidgetEdit.scaleText(root.widgetScale * (root.verticalResizable ? root.widgetHeightScale : 1)),
                      "width": Math.round(root.width),
                      "height": Math.round(root.height)
                    })
    }
  }

  // Context menu model and handler - menu is created dynamically in PopupMenuWindow
  property var contextMenuModel: {
    var hasSettings = false;
    if (widgetData && widgetData.id) {
      var widgetId = widgetData.id;
      if (DesktopWidgetRegistry.isPluginWidget(widgetId)) {
        var pluginId = widgetId.replace("plugin:", "");
        var manifest = PluginRegistry.getPluginManifest(pluginId);
        hasSettings = manifest && manifest.entryPoints && (manifest.entryPoints.settings || manifest.entryPoints.desktopWidgetSettings);
      } else {
        hasSettings = DesktopWidgetRegistry.widgetSettingsMap[widgetId] !== undefined;
      }
    }

    var items = [];
    if (hasSettings) {
      items.push({
                   "label": I18n.tr("actions.widget-settings"),
                   "action": "widget-settings",
                   "icon": "settings"
                 });
    }
    items.push({
                 "label": I18n.tr("common.reset"),
                 "action": "reset",
                 "icon": "restore"
               });
    items.push({
                 "label": I18n.tr("actions.raise-to-top"),
                 "action": "raise-to-top",
                 "icon": "stack-front"
               });
    items.push({
                 "label": I18n.tr("actions.lower-to-bottom"),
                 "action": "lower-to-bottom",
                 "icon": "stack-back"
               });
    items.push({
                 "label": I18n.tr("common.delete"),
                 "action": "delete",
                 "icon": "trash"
               });
    return items;
  }

  // Drag MouseArea - handles dragging (left-click)
  MouseArea {
    id: dragArea
    anchors.fill: parent
    z: 1000
    visible: root.editing
    cursorShape: internal.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    property point pressPos: Qt.point(0, 0)

    onPressed: mouse => {
      // Prevent starting new operation if one is already in progress
      if (internal.operationType !== "") {
        return;
      }

      pressPos = Qt.point(mouse.x, mouse.y);
      EditDesktopService.select(root.widgetIndex);
      DesktopWidgetRegistry.manipulatingWidget = root;
      internal.operationType = "drag";
      internal.dragOffsetX = root.x;
      internal.dragOffsetY = root.y;
      internal.isDragging = true;
    }

    onPositionChanged: mouse => {
      if (internal.isDragging && pressed && internal.operationType === "drag") {
        var globalPressPos = mapToItem(root.parent, pressPos.x, pressPos.y);
        var globalCurrentPos = mapToItem(root.parent, mouse.x, mouse.y);

        var deltaX = globalCurrentPos.x - globalPressPos.x;
        var deltaY = globalCurrentPos.y - globalPressPos.y;

        var newX = internal.dragOffsetX + deltaX;
        var newY = internal.dragOffsetY + deltaY;

        // Boundary clamping - allow widgets to go partially off-screen (75% can clip)
        // This gives users more control over positioning while keeping widgets accessible
        var scaledWidth = root.width;
        var scaledHeight = root.height;
        if (root.parent && scaledWidth > 0 && scaledHeight > 0) {
          var minVisibleX = scaledWidth * 0.25;
          var minVisibleY = scaledHeight * 0.25;
          newX = Math.max(-scaledWidth + minVisibleX, Math.min(newX, root.parent.width - minVisibleX));
          newY = Math.max(-scaledHeight + minVisibleY, Math.min(newY, root.parent.height - minVisibleY));
        }

        // Snap to the other widgets' edges and centers, else to the grid
        var snapped = EditGeometry.snap({
                                          "x": newX,
                                          "y": newY,
                                          "width": scaledWidth,
                                          "height": scaledHeight
                                        }, root.siblingRects(), Settings.data.desktopWidgets.gridSnap ? root.gridSize : 0, root.snapThreshold);
        var clamped = EditGeometry.clampPosition(snapped.x, snapped.y, scaledWidth, scaledHeight, root.parent ? root.parent.width : 0, root.parent ? root.parent.height : 0);
        newX = clamped.x;
        newY = clamped.y;
        if (root.parent && root.parent.guides !== undefined)
          root.parent.guides = snapped.guides;

        internal.dragOffsetX = newX;
        internal.dragOffsetY = newY;
      }
    }

    onReleased: mouse => {
      if (internal.isDragging && internal.operationType === "drag" && widgetIndex >= 0 && screen && screen.name) {
        var roundedX = Math.round(internal.dragOffsetX);
        var roundedY = Math.round(internal.dragOffsetY);
        root.updateWidgetData({
                                "x": roundedX,
                                "y": roundedY
                              });

        internal.baseX = roundedX;
        internal.baseY = roundedY;
        internal.isDragging = false;
        internal.operationType = "";
        root.clearGuides();
        if (DesktopWidgetRegistry.manipulatingWidget === root)
          DesktopWidgetRegistry.manipulatingWidget = null;
      }
    }

    onCanceled: {
      internal.isDragging = false;
      internal.operationType = "";
      root.clearGuides();
      if (DesktopWidgetRegistry.manipulatingWidget === root)
        DesktopWidgetRegistry.manipulatingWidget = null;
    }
  }

  // Right-click MouseArea for context menu
  MouseArea {
    id: contextMenuArea
    anchors.fill: parent
    z: 1001
    visible: root.editing
    acceptedButtons: Qt.RightButton
    hoverEnabled: true

    // The old popup menu would sit behind the Edit Desktop screen; the editor shows its own actions
    onPressed: mouse => {
      if (mouse.button === Qt.RightButton)
        EditDesktopService.select(root.widgetIndex);
    }
  }

  // Corner handles for scaling - using Repeater to avoid code duplication
  readonly property real cornerHandleSize: 8 * widgetScale
  readonly property real outlineMargin: DesktopMetrics.marginS
  readonly property color colorHandle: ShellColors.mSecondary

  // Corner handle model: defines position, direction, cursor, and triangle points for each corner
  // xMult/yMult: multipliers for position (0 = left/top edge, 1 = right/bottom edge)
  // xDir/yDir: direction multiplier for scaling (-1 = left/up increases, 1 = right/down increases)
  // cursor: resize cursor type (FDiag for TL-BR diagonal, BDiag for TR-BL diagonal)
  // points: triangle vertices as [x, y] pairs normalized to cornerHandleSize
  readonly property var cornerHandleModel: [
    {
      xMult: 0,
      yMult: 0,
      xDir: -1,
      yDir: -1,
      cursor: Qt.SizeFDiagCursor,
      points: [[0, 0], [1, 0], [0, 1]]
    },
    {
      xMult: 1,
      yMult: 0,
      xDir: 1,
      yDir: -1,
      cursor: Qt.SizeBDiagCursor,
      points: [[1, 0], [1, 1], [0, 0]]
    },
    {
      xMult: 0,
      yMult: 1,
      xDir: -1,
      yDir: 1,
      cursor: Qt.SizeBDiagCursor,
      points: [[0, 1], [0, 0], [1, 1]]
    },
    {
      xMult: 1,
      yMult: 1,
      xDir: 1,
      yDir: 1,
      cursor: Qt.SizeFDiagCursor,
      points: [[1, 1], [1, 0], [0, 1]]
    }
  ]

  Repeater {
    model: root.cornerHandleModel

    delegate: Canvas {
      id: cornerHandle
      required property var modelData
      required property int index

      visible: root.editing && !internal.isDragging && !internal.isResizing
      // Position handles at corners of decoration rectangle (which extends by outlineMargin)
      x: modelData.xMult === 0 ? -outlineMargin : (root.width + outlineMargin - cornerHandleSize)
      y: modelData.yMult === 0 ? -outlineMargin : (root.height + outlineMargin - cornerHandleSize)
      width: cornerHandleSize
      height: cornerHandleSize
      z: 2000

      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = colorHandle;
        ctx.beginPath();
        ctx.moveTo(modelData.points[0][0] * cornerHandleSize, modelData.points[0][1] * cornerHandleSize);
        ctx.lineTo(modelData.points[1][0] * cornerHandleSize, modelData.points[1][1] * cornerHandleSize);
        ctx.lineTo(modelData.points[2][0] * cornerHandleSize, modelData.points[2][1] * cornerHandleSize);
        ctx.closePath();
        ctx.fill();
      }

      Component.onCompleted: requestPaint()
      onVisibleChanged: if (visible)
                          requestPaint()

      Connections {
        target: root
        function onWidthChanged() {
          if (cornerHandle.visible)
            cornerHandle.requestPaint();
        }
        function onHeightChanged() {
          if (cornerHandle.visible)
            cornerHandle.requestPaint();
        }
      }

      MouseArea {
        id: scaleMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: cornerHandle.modelData.cursor
        property point pressPos: Qt.point(0, 0)

        onPressed: mouse => {
          if (internal.operationType !== "") {
            return;
          }
          pressPos = mapToItem(root.parent, mouse.x, mouse.y);
          DesktopWidgetRegistry.manipulatingWidget = root;
          internal.operationType = "scale";
          internal.isScaling = true;
          internal.initialScale = root.widgetScale;
          internal.lastScale = root.widgetScale;
          internal.initialWidth = root.width;
          internal.initialHeight = root.height;
        }

        onPositionChanged: mouse => {
          if (internal.isScaling && pressed && internal.operationType === "scale") {
            var currentPos = mapToItem(root.parent, mouse.x, mouse.y);
            var deltaX = currentPos.x - pressPos.x;
            var deltaY = currentPos.y - pressPos.y;

            // Project delta onto the diagonal direction for this corner
            // xDir/yDir indicate which direction increases scale
            var diagonalDelta = (deltaX * cornerHandle.modelData.xDir + deltaY * cornerHandle.modelData.yDir) / Math.sqrt(2);

            // Scale sensitivity: pixels of drag per 1.0 scale change
            var sensitivity = 150;
            var scaleDelta = diagonalDelta / sensitivity;
            var newScale = Math.max(root.minScale, Math.min(root.maxScale, internal.initialScale + scaleDelta));

            newScale = root.snapScaleToGrid(newScale, (mouse.modifiers & Qt.ShiftModifier) !== 0);

            if (!isNaN(newScale) && newScale > 0) {
              root.widgetScale = newScale;
              internal.lastScale = newScale;
            }
          }
        }

        onReleased: mouse => {
          if (internal.isScaling && internal.operationType === "scale") {
            root.widgetScale = root.snapScaleToGrid(root.widgetScale, (mouse.modifiers & Qt.ShiftModifier) !== 0);
            internal.lastScale = root.widgetScale;
            internal.isScaling = false;
            internal.operationType = "";
            DesktopWidgetRegistry.manipulatingWidget = null;
            root.updateWidgetData({
                                    "scale": root.widgetScale
                                  });
          }
        }

        onCanceled: {
          root.widgetScale = internal.initialScale;
          internal.isScaling = false;
          internal.operationType = "";
          if (DesktopWidgetRegistry.manipulatingWidget === root)
            DesktopWidgetRegistry.manipulatingWidget = null;
          internal.lastScale = root.widgetScale;
        }
      }
    }
  }
  Repeater {
    model: [
      {
        horizontal: true,
        leading: true
      },
      {
        horizontal: true,
        leading: false
      },
      {
        horizontal: false,
        leading: true
      },
      {
        horizontal: false,
        leading: false
      }
    ]

    Rectangle {
      id: edgeHandle
      required property var modelData
      visible: root.editing && !internal.isDragging && !internal.isScaling && (modelData.horizontal ? root.horizontalResizable : root.verticalResizable)
      width: modelData.horizontal ? 6 : 28
      height: modelData.horizontal ? 28 : 6
      radius: 3
      color: root.colorHandle
      x: modelData.horizontal ? (modelData.leading ? -root.outlineMargin - width / 2 : root.width + root.outlineMargin - width / 2) : (root.width - width) / 2
      y: modelData.horizontal ? (root.height - height) / 2 : (modelData.leading ? -root.outlineMargin - height / 2 : root.height + root.outlineMargin - height / 2)
      z: 2500

      MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        acceptedButtons: Qt.LeftButton
        cursorShape: edgeHandle.modelData.horizontal ? Qt.SizeHorCursor : Qt.SizeVerCursor
        property point pressPos: Qt.point(0, 0)

        function resizeAt(mouse) {
          const current = mapToItem(root.parent, mouse.x, mouse.y);
          const horizontal = edgeHandle.modelData.horizontal;
          const delta = horizontal ? current.x - pressPos.x : current.y - pressPos.y;
          const length = horizontal ? internal.initialWidth : internal.initialHeight;
          const natural = horizontal ? root.implicitWidth : root.implicitHeight;
          if (natural <= 0)
            return;
          const minimum = horizontal ? root.minimumWidgetWidth : root.minimumWidgetHeight;
          const step = Settings.data.desktopWidgets.gridSnap ? root.gridSize : 10 * root.widgetScale;
          const next = WidgetEdit.resizedAxis(horizontal ? internal.initialX : internal.initialY, length, delta, edgeHandle.modelData.leading, minimum, Math.max(minimum, natural * 5), step, (mouse.modifiers & Qt.ShiftModifier) !== 0);
          if (horizontal) {
            root.widgetWidthScale = next.length / natural;
            internal.baseX = next.start;
          } else {
            root.widgetHeightScale = next.length / natural;
            internal.baseY = next.start;
          }
        }

        onPressed: mouse => {
          if (internal.operationType !== "")
            return;
          pressPos = mapToItem(root.parent, mouse.x, mouse.y);
          internal.initialX = root.x;
          internal.initialY = root.y;
          internal.initialWidth = root.width;
          internal.initialHeight = root.height;
          internal.initialWidthScale = root.widgetWidthScale;
          internal.initialHeightScale = root.widgetHeightScale;
          internal.operationType = "resize";
          internal.isResizing = true;
          DesktopWidgetRegistry.manipulatingWidget = root;
        }
        onPositionChanged: mouse => {
          if (pressed && internal.operationType === "resize")
            resizeAt(mouse);
        }
        onReleased: mouse => {
          if (internal.operationType !== "resize")
            return;
          resizeAt(mouse);
          internal.isResizing = false;
          internal.operationType = "";
          DesktopWidgetRegistry.manipulatingWidget = null;
          root.updateWidgetData({
                                  widthScale: root.widgetWidthScale,
                                  heightScale: root.widgetHeightScale,
                                  x: Math.round(internal.baseX),
                                  y: Math.round(internal.baseY)
                                });
        }
        onCanceled: {
          root.widgetWidthScale = internal.initialWidthScale;
          root.widgetHeightScale = internal.initialHeightScale;
          internal.baseX = internal.initialX;
          internal.baseY = internal.initialY;
          internal.isResizing = false;
          internal.operationType = "";
          if (DesktopWidgetRegistry.manipulatingWidget === root)
            DesktopWidgetRegistry.manipulatingWidget = null;
        }
      }
    }
  }
}
