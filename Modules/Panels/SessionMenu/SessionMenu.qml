import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../../Helpers/SessionMenuLayout.js" as SessionMenuLayout
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.Compositor
import qs.Services.UI
import qs.Widgets

SmartPanel {
  id: root

  readonly property bool largeButtonsStyle: Settings.data.sessionMenu.largeButtonsStyle || false
  readonly property var tileGeometry: SessionMenuLayout.geometry(powerOptions.length, Settings.data.sessionMenu.largeButtonsLayout, screen?.width || width || 1920, Style.uiScaleRatio)

  // Large buttons style is fullscreen — disable blur behind it
  blurEnabled: !largeButtonsStyle

  // Make panel background transparent for large buttons style
  panelBackgroundColor: largeButtonsStyle ? "transparent" : ShellColors.mSurface

  preferredWidth: largeButtonsStyle ? 0 : Math.round(440 * Style.uiScaleRatio)
  preferredWidthRatio: largeButtonsStyle ? 1.0 : 0
  preferredHeight: {
    if (largeButtonsStyle) {
      return 0; // Use ratio instead
    }
    var headerHeight = Settings.data.sessionMenu.showHeader ? Style.baseWidgetSize * 0.6 : 0;

    var dividerHeight = Settings.data.sessionMenu.showHeader ? Style.marginS : 0;
    var buttonHeight = Style.baseWidgetSize * 1.3 * Style.uiScaleRatio;
    var buttonSpacing = Style.marginS;
    var enabledCount = powerOptions.length;

    var headerSpacing = Settings.data.sessionMenu.showHeader ? Style.margin2L : 0;
    var baseHeight = (Style.marginL * 4) + headerHeight + dividerHeight + headerSpacing;
    var buttonsHeight = enabledCount > 0 ? (buttonHeight * enabledCount) + (buttonSpacing * (enabledCount - 1)) : 0;

    return Math.round(baseHeight + buttonsHeight);
  }
  preferredHeightRatio: largeButtonsStyle ? 1.0 : 0

  // Positioning - large buttons style is always centered and fullscreen
  readonly property string panelPosition: Settings.data.sessionMenu.position

  panelAnchorHorizontalCenter: largeButtonsStyle || panelPosition === "center" || panelPosition.endsWith("_center")
  panelAnchorVerticalCenter: largeButtonsStyle || panelPosition === "center"
  panelAnchorLeft: !largeButtonsStyle && panelPosition !== "center" && panelPosition.endsWith("_left")
  panelAnchorRight: !largeButtonsStyle && panelPosition !== "center" && panelPosition.endsWith("_right")
  panelAnchorBottom: !largeButtonsStyle && panelPosition.startsWith("bottom_")
  panelAnchorTop: !largeButtonsStyle && panelPosition.startsWith("top_")

  // SessionMenu handle it's own closing logic
  property bool closeWithEscape: false

  // Timer properties
  readonly property int timerDuration: Settings.data.sessionMenu.countdownDuration
  property string pendingAction: ""
  property bool timerActive: false
  property int timeRemaining: 0

  // Navigation properties
  property int selectedIndex: -1
  property bool ignoreMouseHover: true // Transient flag, should always be true on init

  // Global mouse tracking for movement detection across delegates
  property real globalLastMouseX: 0
  property real globalLastMouseY: 0
  property bool globalMouseInitialized: false
  property bool mouseTrackingReady: false // Delay tracking until panel is settled

  Timer {
    id: mouseTrackingDelayTimer
    interval: Style.animationNormal + 50 // Wait for panel animation to complete + safety margin
    repeat: false
    onTriggered: {
      root.mouseTrackingReady = true;
      root.globalMouseInitialized = false; // Reset so we get fresh initial position
    }
  }

  // Action metadata mapping
  readonly property var actionMetadata: {
    "lock": {
      "icon": "lock",
      "title": I18n.tr("common.lock"),
      "isShutdown": false
    },
    "suspend": {
      "icon": "suspend",
      "title": I18n.tr("common.suspend"),
      "isShutdown": false
    },
    "hibernate": {
      "icon": "hibernate",
      "title": I18n.tr("common.hibernate"),
      "isShutdown": false
    },
    "reboot": {
      "icon": "reboot",
      "title": I18n.tr("common.reboot"),
      "isShutdown": false
    },
    "userspaceReboot": {
      "icon": "rotate",
      "title": I18n.tr("common.userspace-reboot"),
      "isShutdown": false
    },
    "rebootToUefi": {
      "icon": "reboot",
      "title": I18n.tr("common.reboot-to-uefi"),
      "isShutdown": false
    },
    "logout": {
      "icon": "logout",
      "title": I18n.tr("common.logout"),
      "isShutdown": false
    },
    "shutdown": {
      "icon": "shutdown",
      "title": I18n.tr("common.shutdown"),
      "isShutdown": true
    }
  }

  // Build powerOptions from settings, filtering enabled ones and adding metadata
  // _powerOptionsVersion forces re-evaluation when settings change
  property int _powerOptionsVersion: 0
  property var powerOptions: {
    // Reference version to trigger re-evaluation
    void (_powerOptionsVersion);
    var options = [];
    var settingsOptions = Settings.data.sessionMenu.powerOptions || [];

    for (var i = 0; i < settingsOptions.length; i++) {
      var settingOption = settingsOptions[i];
      if (settingOption.enabled && actionMetadata[settingOption.action]) {
        var metadata = actionMetadata[settingOption.action];
        options.push({
                       "action": settingOption.action,
                       "icon": metadata.icon,
                       "title": metadata.title,
                       "isShutdown": metadata.isShutdown,
                       "countdownEnabled": settingOption.countdownEnabled !== undefined ? settingOption.countdownEnabled : true,
                       "command": settingOption.command || "",
                       "keybind": settingOption.keybind || ""
                     });
      }
    }

    return options;
  }

  Connections {
    target: Settings.data.sessionMenu
    function onPowerOptionsChanged() {
      root._powerOptionsVersion++;
    }
  }

  // Lifecycle handlers
  onOpened: {
    if (powerOptions.length > 0) {
      selectedIndex = -1;
      ignoreMouseHover = true;
      globalMouseInitialized = false;
      mouseTrackingReady = false;
      mouseTrackingDelayTimer.restart();
    } else {
      Logger.w("SessionMenu", "Trying to open an empty session menu");
      root.closeImmediately();
    }
  }

  onClosed: {
    cancelTimer();
    selectedIndex = -1;
    ignoreMouseHover = true;
  }

  // Timer management
  function startTimer(action) {
    // Check if global countdown is disabled
    if (!Settings.data.sessionMenu.enableCountdown) {
      executeAction(action);
      return;
    }

    // Check per-item countdown setting
    var option = null;
    for (var i = 0; i < powerOptions.length; i++) {
      if (powerOptions[i].action === action) {
        option = powerOptions[i];
        break;
      }
    }

    // If this specific action has countdown disabled, execute immediately
    if (option && option.countdownEnabled === false) {
      executeAction(action);
      return;
    }

    if (timerActive && pendingAction === action) {
      // Second click - execute immediately
      executeAction(action);
      return;
    }

    pendingAction = action;
    timeRemaining = timerDuration;
    timerActive = true;
    countdownTimer.start();
  }

  function cancelTimer() {
    timerActive = false;
    pendingAction = "";
    timeRemaining = 0;
    countdownTimer.stop();
  }

  function executeAction(action) {
    // Stop timer but don't reset other properties yet
    countdownTimer.stop();

    // Use default behavior or custom command handled by CompositorService
    switch (action) {
    case "lock":
      CompositorService.lock();
      break;
    case "suspend":
      CompositorService.suspend();
      break;
    case "hibernate":
      CompositorService.hibernate();
      break;
    case "reboot":
      CompositorService.reboot();
      break;
    case "userspaceReboot":
      CompositorService.userspaceReboot();
      break;
    case "rebootToUefi":
      CompositorService.rebootToUefi();
      break;
    case "logout":
      CompositorService.logout();
      break;
    case "shutdown":
      CompositorService.shutdown();
      break;
    }

    // Reset timer state and close panel
    cancelTimer();
    root.close();
  }

  // Navigation functions
  function selectNextWrapped() {
    if (powerOptions.length > 0) {
      if (selectedIndex < 0) {
        selectedIndex = 0;
      } else {
        selectedIndex = (selectedIndex + 1) % powerOptions.length;
      }
    }
  }

  function selectPreviousWrapped() {
    if (powerOptions.length > 0) {
      if (selectedIndex < 0) {
        selectedIndex = powerOptions.length - 1;
      } else {
        selectedIndex = (((selectedIndex - 1) % powerOptions.length) + powerOptions.length) % powerOptions.length;
      }
    }
  }

  function selectFirst() {
    if (powerOptions.length > 0) {
      selectedIndex = 0;
    } else {
      selectedIndex = -1;
    }
  }

  function selectLast() {
    if (powerOptions.length > 0) {
      selectedIndex = powerOptions.length - 1;
    } else {
      selectedIndex = -1;
    }
  }

  function navigateGrid(direction) {
    selectedIndex = SessionMenuLayout.navigate(powerOptions.length, tileGeometry.columns, selectedIndex, direction);
  }

  function activate() {
    if (powerOptions.length > 0 && selectedIndex >= 0 && powerOptions[selectedIndex]) {
      const option = powerOptions[selectedIndex];
      startTimer(option.action);
    }
  }

  function checkKey(event, settingName) {
    return Keybinds.checkKey(event, settingName, Settings);
  }

  function handleUp() {
    if (largeButtonsStyle) {
      navigateGrid("up");
    } else {
      selectPreviousWrapped();
    }
  }

  function handleDown() {
    if (largeButtonsStyle) {
      navigateGrid("down");
    } else {
      selectNextWrapped();
    }
  }

  function handleLeft() {
    if (largeButtonsStyle) {
      navigateGrid("left");
    } else {
      selectPreviousWrapped();
    }
  }

  function handleRight() {
    if (largeButtonsStyle) {
      navigateGrid("right");
    } else {
      selectNextWrapped();
    }
  }

  function handleEnter() {
    activate();
  }

  function handleEscape() {
    if (timerActive) {
      cancelTimer();
    } else {
      root.close();
    }
  }

  // Override keyboard handlers from SmartPanel
  function onEscapePressed() {
    handleEscape();
  }
  function onTabPressed() {
    selectNextWrapped();
  }
  function onBackTabPressed() {
    selectPreviousWrapped();
  }
  function onLeftPressed() {
    handleLeft();
  }
  function onRightPressed() {
    handleRight();
  }
  function onUpPressed() {
    handleUp();
  }
  function onDownPressed() {
    handleDown();
  }
  function onEnterPressed() {
    handleEnter();
  }
  function onHomePressed() {
    selectFirst();
  }
  function onEndPressed() {
    selectLast();
  }

  function checkKeybind(event) {
    if (powerOptions.length === 0)
      return false;

    // Construct key string in the same format as the recorder
    // Ignore modifier keys by themselves
    if (event.key === Qt.Key_Control || event.key === Qt.Key_Shift || event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) {
      return false;
    }

    const pressedKeybind = Keybinds.getKeybindString(event);
    if (!pressedKeybind)
      return false;

    for (var i = 0; i < powerOptions.length; i++) {
      const option = powerOptions[i];
      if (option.keybind === pressedKeybind) {
        selectedIndex = i;
        startTimer(option.action);
        return true;
      }
    }
    return false;
  }

  // Countdown timer
  Timer {
    id: countdownTimer
    interval: 100
    repeat: true
    onTriggered: {
      timeRemaining -= interval;
      if (timeRemaining <= 0) {
        executeAction(pendingAction);
      }
    }
  }

  panelContent: Rectangle {
    id: panelContent
    color: "transparent"
    focus: true

    // For large buttons style, use full screen dimensions
    readonly property var contentPreferredWidth: largeButtonsStyle ? (root.screen?.width || root.width || 0) : undefined
    readonly property var contentPreferredHeight: largeButtonsStyle ? (root.screen?.height || root.height || 0) : undefined

    // Focus management
    Connections {
      target: root
      function onOpened() {
        Qt.callLater(() => {
          panelContent.forceActiveFocus();
        });
      }
    }

    Keys.onPressed: event => {
      // Check custom entry keybinds first
      if (root.checkKeybind(event)) {
        event.accepted = true;
        return;
      }

      // Check global navigation keybinds
      if (checkKey(event, 'up')) {
        handleUp();
        event.accepted = true;
        return;
      }
      if (checkKey(event, 'down')) {
        handleDown();
        event.accepted = true;
        return;
      }
      if (checkKey(event, 'left')) {
        handleLeft();
        event.accepted = true;
        return;
      }
      if (checkKey(event, 'right')) {
        handleRight();
        event.accepted = true;
        return;
      }
      if (checkKey(event, 'enter')) {
        handleEnter();
        event.accepted = true;
        return;
      }
      if (checkKey(event, 'escape')) {
        handleEscape();
        event.accepted = true;
        return;
      }

      // Block default keys if they weren't matched above
      // This prevents 'Up' from working if rebinned to something else
      if (event.key === Qt.Key_Up || event.key === Qt.Key_Down || event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Escape) {
        event.accepted = true;
        return;
      }
    }

    HoverHandler {
      id: globalHoverHandler

      onPointChanged: {
        if (!root.mouseTrackingReady) {
          return;
        }

        if (!root.globalMouseInitialized) {
          root.globalLastMouseX = point.position.x;
          root.globalLastMouseY = point.position.y;
          root.globalMouseInitialized = true;
          return;
        }

        const deltaX = Math.abs(point.position.x - root.globalLastMouseX);
        const deltaY = Math.abs(point.position.y - root.globalLastMouseY);
        if (deltaX + deltaY >= 5) {
          root.ignoreMouseHover = false;
          root.globalLastMouseX = point.position.x;
          root.globalLastMouseY = point.position.y;
        }
      }
    }

    // One surface keeps the fullscreen menu readable over busy desktops.
    Rectangle {
      id: largeButtonsContainer
      visible: largeButtonsStyle
      anchors.centerIn: parent
      width: root.tileGeometry.width
      height: Math.min(largeContent.implicitHeight + root.tileGeometry.padding * 2, panelContent.height - Style.margin2L)
      radius: Style.radiusL
      color: ShellColors.mSurface
      border.color: ShellColors.mOutline
      border.width: Style.borderS

      // Absorb clicks inside the card, including gaps between actions.
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
      }

      ColumnLayout {
        id: largeContent
        anchors.fill: parent
        anchors.margins: root.tileGeometry.padding
        spacing: Style.marginL

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          NIcon {
            icon: "shutdown"
            pointSize: Style.fontSizeXXL
            color: ShellColors.mPrimary
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS
            NText {
              Layout.fillWidth: true
              text: I18n.tr("session-menu.title")
              pointSize: Style.fontSizeXL
              font.weight: Style.fontWeightBold
            }
            NText {
              Layout.fillWidth: true
              text: I18n.tr("session-menu.choose-action")
              color: ShellColors.mOnSurfaceVariant
              pointSize: Style.fontSizeS
              wrapMode: Text.WordWrap
            }
          }

          NIconButton {
            icon: "close"
            tooltipText: I18n.tr("common.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: root.close()
          }
        }

        NDivider {
          Layout.fillWidth: true
        }

        Flickable {
          id: actionScroll
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.preferredHeight: largeButtonsGrid.implicitHeight
          Layout.minimumHeight: 0
          contentHeight: largeButtonsGrid.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          ScrollBar.vertical: NScrollBar {}

          function revealSelection() {
            if (root.selectedIndex < 0)
              return;
            const top = Math.floor(root.selectedIndex / root.tileGeometry.columns) * (root.tileGeometry.tileHeight + root.tileGeometry.gap);
            contentY = Math.max(0, Math.min(top, Math.max(contentY, top + root.tileGeometry.tileHeight - height)));
          }
          Connections {
            target: root
            function onSelectedIndexChanged() {
              actionScroll.revealSelection();
            }
          }

          GridLayout {
            id: largeButtonsGrid
            width: parent.width
            columns: root.tileGeometry.columns
            rowSpacing: root.tileGeometry.gap
            columnSpacing: root.tileGeometry.gap

            Repeater {
              model: powerOptions
              delegate: LargeButton {
                Layout.fillWidth: true
                Layout.preferredWidth: root.tileGeometry.tileWidth
                Layout.preferredHeight: root.tileGeometry.tileHeight
                icon: modelData.icon
                title: modelData.title
                isShutdown: modelData.isShutdown || false
                isSelected: index === selectedIndex
                buttonIndex: index
                onClicked: {
                  selectedIndex = index;
                  startTimer(modelData.action);
                }
                pending: timerActive && pendingAction === modelData.action
                keybind: modelData.keybind || ""
              }
            }
          }
        }

        NDivider {
          Layout.fillWidth: true
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM
          NText {
            Layout.fillWidth: true
            text: timerActive ? I18n.tr("session-menu.action-in-seconds", {
                                          "action": root.actionMetadata[pendingAction] ? root.actionMetadata[pendingAction].title : "",
                                          "seconds": Math.ceil(timeRemaining / 1000)
                                        }) : I18n.tr("session-menu.dismiss-hint")
            color: timerActive ? ShellColors.mPrimary : ShellColors.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            wrapMode: Text.WordWrap
          }
          NButton {
            visible: timerActive
            text: I18n.tr("common.cancel")
            outlined: true
            onClicked: cancelTimer()
          }
        }
      }
    }

    // Normal style layout
    NBox {
      visible: !largeButtonsStyle
      anchors.fill: parent
      anchors.margins: Style.marginL
      color: ShellColors.mSurfaceVariant

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginL

        // Header with title and close button
        RowLayout {
          visible: Settings.data.sessionMenu.showHeader
          Layout.fillWidth: true
          Layout.preferredHeight: Style.baseWidgetSize * 0.6

          NText {
            text: timerActive ? I18n.tr("session-menu.action-in-seconds", {
                                          "action": root.actionMetadata[pendingAction] ? root.actionMetadata[pendingAction].title : "",
                                          "seconds": Math.ceil(timeRemaining / 1000)
                                        }) : I18n.tr("session-menu.title")
            font.weight: Style.fontWeightBold
            pointSize: Style.fontSizeL
            color: timerActive ? ShellColors.mPrimary : ShellColors.mOnSurface
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
          }

          Item {
            Layout.fillWidth: true
          }

          NIconButton {
            icon: timerActive ? "stop" : "close"
            tooltipText: timerActive ? I18n.tr("session-menu.cancel-timer") : I18n.tr("common.close")
            Layout.alignment: Qt.AlignVCenter
            baseSize: Style.baseWidgetSize * 0.7
            colorBg: timerActive ? Qt.alpha(ShellColors.mError, 0.08) : "transparent"
            colorFg: timerActive ? ShellColors.mError : ShellColors.mOnSurface
            onClicked: {
              if (timerActive) {
                cancelTimer();
              } else {
                cancelTimer();
                root.close();
              }
            }
          }
        }

        NDivider {
          visible: Settings.data.sessionMenu.showHeader
          Layout.fillWidth: true
        }

        // Power options
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          Repeater {
            model: powerOptions
            delegate: PowerButton {
              Layout.fillWidth: true
              icon: modelData.icon
              title: modelData.title
              isShutdown: modelData.isShutdown || false
              isSelected: index === selectedIndex
              number: index + 1
              buttonIndex: index
              onClicked: {
                selectedIndex = index;
                startTimer(modelData.action);
              }
              pending: timerActive && pendingAction === modelData.action
              keybind: modelData.keybind || ""
            }
          }
        }
      }
    }

    // Background MouseArea for large buttons style - closes panel when clicking outside buttons
    MouseArea {
      visible: largeButtonsStyle
      anchors.fill: parent
      z: -1
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: mouse => {
        // Only close if not clicking on a button
        // The buttons are above this MouseArea, so clicks on them won't reach here
        if (timerActive) {
          // Cancel countdown if active
          cancelTimer();
        } else {
          root.close();
        }
      }
    }
  }

  // Custom power button component
  component PowerButton: Rectangle {
    id: buttonRoot

    property string icon: ""
    property string title: ""
    property bool pending: false
    property bool isShutdown: false
    property bool isSelected: false
    property int number: 0
    property string keybind: ""
    property int buttonIndex: -1

    // Effective hover state that respects ignoreMouseHover
    readonly property bool effectiveHover: !root.ignoreMouseHover && mouseArea.containsMouse

    signal clicked

    height: Style.baseWidgetSize * 1.3 * Style.uiScaleRatio
    radius: Style.radiusS
    color: {
      if (pending) {
        return Qt.alpha(ShellColors.mPrimary, 0.08);
      }
      if (isSelected || effectiveHover) {
        return ShellColors.mHover;
      }
      return "transparent";
    }

    border.width: pending ? Math.max(Style.borderM) : 0
    border.color: pending ? ShellColors.mPrimary : ShellColors.mOutline

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCirc
      }
    }

    Item {
      id: contentItem
      anchors.fill: parent
      anchors.margins: Style.marginM

      // Icon on the left
      NIcon {
        id: iconElement
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        icon: buttonRoot.icon
        color: {
          if (buttonRoot.pending)
            return ShellColors.mPrimary;
          if (buttonRoot.isShutdown && !buttonRoot.isSelected && !buttonRoot.effectiveHover)
            return ShellColors.mError;
          if (buttonRoot.isSelected || buttonRoot.effectiveHover)
            return ShellColors.mOnHover;
          return ShellColors.mOnSurface;
        }
        pointSize: Style.fontSizeXXL
        width: Style.baseWidgetSize * 0.5
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCirc
          }
        }
      }

      // Keybind indicator and countdown text at far right
      Item {
        id: indicatorGroup
        width: (countdownText.visible ? countdownText.width + Style.marginXS : 0) + numberIndicatorRect.width
        height: numberIndicatorRect.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        z: 20

        // Countdown as plain text (left of keybind)
        NText {
          id: countdownText
          visible: !Settings.data.sessionMenu.showHeader && buttonRoot.pending && timerActive && pendingAction === modelData.action
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: Math.ceil(timeRemaining / 1000)
          pointSize: Style.fontSizeS
          color: ShellColors.mPrimary
          font.weight: Style.fontWeightBold
        }

        // Keybind indicator
        Rectangle {
          id: numberIndicatorRect
          anchors.left: countdownText.visible ? countdownText.right : parent.left
          anchors.leftMargin: countdownText.visible ? Style.marginXS : 0
          anchors.verticalCenter: parent.verticalCenter
          width: labelText.implicitWidth + Style.margin2M
          height: labelText.height + Style.margin2XS
          radius: Math.min(Style.radiusM, height / 2)
          color: (buttonRoot.isSelected || buttonRoot.effectiveHover) ? ShellColors.mOnPrimary : ShellColors.mSurface
          border.width: Style.borderS
          border.color: (buttonRoot.isSelected || buttonRoot.effectiveHover) ? ShellColors.mOnPrimary : ShellColors.mOutline
          visible: Settings.data.sessionMenu.showKeybinds && (buttonRoot.keybind !== "") && !buttonRoot.pending

          NText {
            id: labelText
            anchors.centerIn: parent
            text: buttonRoot.keybind
            pointSize: Style.fontSizeXS
            color: (buttonRoot.isSelected || buttonRoot.effectiveHover) ? ShellColors.mPrimary : ShellColors.mOnSurface

            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
                easing.type: Easing.OutCirc
              }
            }
          }
        }
      }

      // Text content in the middle
      ColumnLayout {
        anchors.left: iconElement.right
        anchors.right: indicatorGroup.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.marginL
        anchors.rightMargin: Style.marginM
        spacing: 0

        NText {
          text: buttonRoot.title
          font.weight: Style.fontWeightMedium
          pointSize: Style.fontSizeM
          color: {
            if (buttonRoot.pending)
              return ShellColors.mPrimary;
            if (buttonRoot.isShutdown && !buttonRoot.isSelected && !buttonRoot.effectiveHover)
              return ShellColors.mError;
            if (buttonRoot.isSelected || buttonRoot.effectiveHover)
              return ShellColors.mOnHover;
            return ShellColors.mOnSurface;
          }

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
              easing.type: Easing.OutCirc
            }
          }
        }
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onEntered: {
        if (!root.ignoreMouseHover) {
          selectedIndex = buttonRoot.buttonIndex;
        }
      }

      onExited: {
        if (!root.ignoreMouseHover && selectedIndex === buttonRoot.buttonIndex) {
          selectedIndex = -1;
        }
      }

      onClicked: buttonRoot.clicked()
    }
  }

  // Large buttons style button component
  component LargeButton: Rectangle {
    id: largeButtonRoot

    property string icon: ""
    property string title: ""
    property bool pending: false
    property bool isShutdown: false
    property bool isSelected: false
    property int number: 0
    property string keybind: ""
    property int buttonIndex: -1

    // Effective hover state that respects ignoreMouseHover
    readonly property bool effectiveHover: !root.ignoreMouseHover && mouseArea.containsMouse

    signal clicked

    radius: Style.radiusM
    color: {
      if (pending) {
        return Qt.alpha(ShellColors.mPrimary, 0.18);
      }
      if (isSelected || effectiveHover) {
        return Qt.alpha(ShellColors.mPrimary, 0.18);
      }
      return ShellColors.mSurfaceVariant;
    }

    border.width: Style.borderS
    border.color: (pending || isSelected || effectiveHover) ? (isShutdown ? ShellColors.mError : ShellColors.mPrimary) : Qt.alpha(ShellColors.mOutline, 0.5)

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCirc
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      anchors.topMargin: Style.marginL
      spacing: Style.marginM

      // Keep the icon steady while the surface responds to focus.
      NIcon {
        id: iconElement
        Layout.alignment: Qt.AlignHCenter
        icon: largeButtonRoot.icon
        color: {
          if (largeButtonRoot.pending)
            return largeButtonRoot.isShutdown ? ShellColors.mError : ShellColors.mPrimary;
          if (largeButtonRoot.isShutdown)
            return ShellColors.mError;
          if (largeButtonRoot.isSelected || largeButtonRoot.effectiveHover)
            return ShellColors.mPrimary;
          return ShellColors.mOnSurface;
        }
        pointSize: Style.fontSizeXXXL * 1.25
        width: 48 * Style.uiScaleRatio
        height: 48 * Style.uiScaleRatio
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCirc
          }
        }
      }

      // Title text
      NText {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        text: largeButtonRoot.title
        font.weight: Style.fontWeightMedium
        pointSize: Style.fontSizeM
        color: {
          if (largeButtonRoot.pending)
            return largeButtonRoot.isShutdown ? ShellColors.mError : ShellColors.mPrimary;
          if (largeButtonRoot.isShutdown)
            return ShellColors.mError;
          if (largeButtonRoot.isSelected || largeButtonRoot.effectiveHover)
            return ShellColors.mPrimary;
          return ShellColors.mOnSurface;
        }

        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCirc
          }
        }
      }
    }

    // Keybind/Number indicator in top-right corner
    Rectangle {
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: Style.marginM
      width: largeNumberText.implicitWidth + Style.margin2M
      height: largeNumberText.implicitHeight + Style.margin2XS
      radius: Math.min(Style.radiusM, height / 2)
      color: (largeButtonRoot.isSelected || largeButtonRoot.effectiveHover) ? ShellColors.mPrimary : Qt.alpha(ShellColors.mSurfaceVariant, 0.7)
      border.width: Style.borderS
      border.color: (largeButtonRoot.isSelected || largeButtonRoot.effectiveHover) ? ShellColors.mPrimary : ShellColors.mOutline
      visible: Settings.data.sessionMenu.showKeybinds && (largeButtonRoot.keybind !== "") && !largeButtonRoot.pending
      z: 10

      NText {
        id: largeNumberText
        anchors.centerIn: parent
        text: largeButtonRoot.keybind
        pointSize: Style.fontSizeS
        color: {
          if (largeButtonRoot.isSelected || largeButtonRoot.effectiveHover)
            return ShellColors.mOnPrimary;
          return ShellColors.mOnSurfaceVariant;
        }

        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCirc
          }
        }
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onEntered: {
        if (!root.ignoreMouseHover) {
          selectedIndex = largeButtonRoot.buttonIndex;
        }
      }

      onExited: {
        if (!root.ignoreMouseHover && selectedIndex === largeButtonRoot.buttonIndex) {
          selectedIndex = -1;
        }
      }

      onClicked: largeButtonRoot.clicked()
    }
  }
}
