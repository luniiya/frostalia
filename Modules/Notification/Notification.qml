import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets
import "../../Helpers/NotificationMotion.js" as NotificationMotion
import qs.Commons
import qs.Services.System
import qs.Widgets

// Simple notification popup - displays multiple notifications
Variants {

  model: {
    const screens = Quickshell.screens.filter(screen => Settings.data.notifications.monitors.includes(screen.name));
    // Empty list can mean two things :
    // - No (visible) notification display activated in settings
    // - One or more (not visible) displays are activated but unplugged
    // In both cases we fallback to show notification on all screens
    return screens.length === 0 ? Quickshell.screens : screens;
  }

  delegate: Loader {
    id: root

    required property ShellScreen modelData

    property ListModel notificationModel: NotificationService.popupModel

    // Deferred activation via Qt.callLater to avoid activating the Loader
    // synchronously during ListModel.insert() (which would cause nested
    // incubation with the inner Repeater).
    property bool shouldBeActive: false
    active: shouldBeActive || delayTimer.running

    // Keep loader active briefly after last notification to allow animations to complete
    Timer {
      id: delayTimer
      interval: Style.animationSlow + 200
      repeat: false
    }

    function activate() {
      shouldBeActive = true;
    }

    Connections {
      target: notificationModel
      function onCountChanged() {
        if (notificationModel.count > 0) {
          if (!root.shouldBeActive) {
            Qt.callLater(root.activate);
          }
        } else if (root.shouldBeActive) {
          root.shouldBeActive = false;
          delayTimer.restart();
        }
      }
    }

    sourceComponent: PanelWindow {
      id: notifWindow
      screen: modelData

      WlrLayershell.namespace: "frostalia-notifications-" + (screen?.name || "unknown")
      WlrLayershell.layer: (Settings.data.notifications?.overlayLayer) ? WlrLayer.Overlay : WlrLayer.Top
      WlrLayershell.exclusionMode: ExclusionMode.Ignore

      color: "transparent"

      // Only the transformed card surfaces accept input. The larger Material
      // canvas remains click-through, including gaps between notifications.
      mask: notifWindow.material ? materialInputMask : legacyInputMask
      property Region materialInputMask: Region {
        regions: notificationRepeater.inputRegions
      }
      property Region legacyInputMask: Region {
        x: 0
        y: 0
        width: notifWindow.width
        height: notifWindow.height
        intersection: Intersection.Xor
        Region {
          x: notifWindow.shadowPadding
          y: notifWindow.shadowPadding
          width: notifWindow.notifWidth
          height: Math.max(0, notifWindow.height - notifWindow.shadowPadding * 2)
          intersection: Intersection.Subtract
        }
      }

      // Parse location setting
      readonly property string location: Settings.data.notifications.location || "top_right"
      readonly property bool isTop: location.startsWith("top")
      readonly property bool isBottom: location.startsWith("bottom")
      readonly property bool isLeft: location.endsWith("_left")
      readonly property bool isRight: location.endsWith("_right")
      readonly property bool isCentered: location === "top" || location === "bottom"

      readonly property string barPos: Settings.getBarPositionForScreen(notifWindow.screen?.name)
      readonly property bool isFloating: Settings.data.bar.barType === "floating"
      readonly property real barHeight: Style.getBarHeightForScreen(notifWindow.screen?.name)

      readonly property bool isFramed: Settings.data.bar.barType === "framed"
      readonly property real frameThickness: Settings.data.bar.frameThickness ?? 8

      readonly property bool material: Style.materialControls
      readonly property bool isCompact: Settings.data.notifications.density === "compact"
      readonly property int notifWidth: Math.round((isCompact ? 320 : 440) * Style.uiScaleRatio)
      readonly property int baseShadowPadding: Style.shadowBlurMax + Style.marginL
      readonly property int motionPadding: material ? Math.round(160 * Style.uiScaleRatio) : 0
      readonly property int shadowPadding: baseShadowPadding + motionPadding

      // Calculate bar and frame offsets for each edge separately
      readonly property int barOffsetTop: {
        if (barPos !== "top")
          return isFramed ? frameThickness : 0;
        const floatMarginV = isFloating ? Math.ceil(Settings.data.bar.marginVertical) : 0;
        return barHeight + floatMarginV;
      }

      readonly property int barOffsetBottom: {
        if (barPos !== "bottom")
          return isFramed ? frameThickness : 0;
        const floatMarginV = isFloating ? Math.ceil(Settings.data.bar.marginVertical) : 0;
        return barHeight + floatMarginV;
      }

      readonly property int barOffsetLeft: {
        if (barPos !== "left")
          return isFramed ? frameThickness : 0;
        const floatMarginH = isFloating ? Math.ceil(Settings.data.bar.marginHorizontal) : 0;
        return barHeight + floatMarginH;
      }

      readonly property int barOffsetRight: {
        if (barPos !== "right")
          return isFramed ? frameThickness : 0;
        const floatMarginH = isFloating ? Math.ceil(Settings.data.bar.marginHorizontal) : 0;
        return barHeight + floatMarginH;
      }

      // Anchoring
      anchors.top: isTop
      anchors.bottom: isBottom
      anchors.left: isLeft
      anchors.right: isRight

      // Margins for PanelWindow - only apply bar offset for the specific edge where the bar is
      margins.top: isTop ? barOffsetTop - shadowPadding + Style.marginM : 0
      margins.bottom: isBottom ? barOffsetBottom - shadowPadding : 0
      margins.left: isLeft ? barOffsetLeft - shadowPadding + Style.marginM : 0
      margins.right: isRight ? barOffsetRight - shadowPadding + Style.marginM : 0

      implicitWidth: notifWidth + shadowPadding * 2
      implicitHeight: notificationStack.implicitHeight + Style.marginL

      property var animateConnection: null

      Component.onCompleted: {
        animateConnection = function (notificationId) {
          var delegate = null;
          if (notificationRepeater) {
            for (var i = 0; i < notificationRepeater.count; i++) {
              var item = notificationRepeater.itemAt(i);
              if (item?.notificationId === notificationId) {
                delegate = item;
                break;
              }
            }
          }

          try {
            if (delegate && typeof delegate.animateOut === "function" && !delegate.isRemoving) {
              delegate.animateOut();
            }
          } catch (e) {
            // Service fallback if delegate is already invalid
            NotificationService.dismissPopup(notificationId);
          }
        };

        NotificationService.animateAndRemove.connect(animateConnection);
      }

      Component.onDestruction: {
        if (animateConnection) {
          NotificationService.animateAndRemove.disconnect(animateConnection);
          animateConnection = null;
        }
      }

      ColumnLayout {
        id: notificationStack

        anchors {
          top: parent.isTop ? parent.top : undefined
          bottom: parent.isBottom ? parent.bottom : undefined
          left: parent.isLeft ? parent.left : undefined
          right: parent.isRight ? parent.right : undefined
          horizontalCenter: parent.isCentered ? parent.horizontalCenter : undefined
        }

        spacing: -notifWindow.shadowPadding * 2 + Style.marginM

        Behavior on implicitHeight {
          enabled: !Settings.data.general.animationDisabled
          SpringAnimation {
            spring: 2.0
            damping: 0.4
            epsilon: 0.01
            mass: 0.8
          }
        }

        Repeater {
          id: notificationRepeater
          model: notificationModel
          property var inputRegions: []
          function updateInputRegions() {
            const regions = [];
            for (let i = 0; i < count; i++) {
              const card = itemAt(i);
              if (card)
                regions.push(card.inputRegion);
            }
            inputRegions = regions;
          }
          onItemAdded: Qt.callLater(updateInputRegions)
          onItemRemoved: Qt.callLater(updateInputRegions)

          delegate: Item {
            id: card

            property string notificationId: model.id
            property var notificationData: model
            property bool isHovered: false
            property bool isRemoving: false

            readonly property int animationDelay: index * (notifWindow.material ? 45 : 100)
            readonly property int slideDistance: 300

            Layout.preferredWidth: notifWidth + notifWindow.shadowPadding * 2
            Layout.preferredHeight: notificationContentLoader.implicitHeight + (notifWindow.material ? 2 * Style.marginL : 0) + notifWindow.shadowPadding * 2
            Layout.maximumHeight: Layout.preferredHeight

            // Animation properties
            property real scaleValue: 0.8
            property real opacityValue: 0.0
            property real slideOffset: 0
            property real swipeOffset: 0
            property real swipeOffsetY: 0
            property real rawDragX: 0
            property real rawDragY: 0
            property real velocityX: 0
            property real velocityY: 0
            property real sampleTime: 0
            property real springTime: 0
            readonly property real dragLimit: Math.max(8, notifWindow.motionPadding)
            readonly property real edgeLimit: Math.max(2, Style.marginS)
            function dragBound(delta, horizontal) {
              const towardEdge = horizontal ? (delta > 0 ? notifWindow.isRight : notifWindow.isLeft) : (delta > 0 ? notifWindow.isBottom : notifWindow.isTop);
              return towardEdge ? edgeLimit : dragLimit;
            }
            // Explicit dependencies keep the Wayland input mask aligned while
            // drag and entry animations transform the visual card.
            readonly property point inputOrigin: {
              const origin = card.parent.mapToItem(null, card.x, card.y);
              const point = NotificationMotion.inputOrigin(origin.x, origin.y, card.width, card.height, displayedCard.x, displayedCard.y, card.scale, card.swipeOffset, card.slideOffset + card.swipeOffsetY);
              return Qt.point(point.x, point.y);
            }
            readonly property Region inputRegion: Region {
              x: Math.floor(card.inputOrigin.x)
              y: Math.floor(card.inputOrigin.y)
              width: Math.ceil(displayedCard.width * card.scale)
              height: Math.ceil(displayedCard.height * card.scale)
              radius: Math.round(cardBackground.radius * card.scale)
            }
            property real pressGlobalX: 0
            property real pressGlobalY: 0
            property bool isSwiping: false
            property bool suppressClick: false
            readonly property bool useVerticalSwipe: notifWindow.location === "bottom" || notifWindow.location === "top"
            readonly property real swipeStartThreshold: Math.round(18 * Style.uiScaleRatio)
            readonly property real swipeDismissThreshold: Math.max(110, cardBackground.width * 0.32)
            readonly property real verticalSwipeDismissThreshold: Math.max(70, cardBackground.height * 0.35)

            scale: scaleValue
            opacity: opacityValue
            transform: Translate {
              x: card.swipeOffset
              y: card.slideOffset + card.swipeOffsetY
            }

            readonly property real slideInOffset: notifWindow.isTop ? -slideDistance : slideDistance
            readonly property real slideOutOffset: slideInOffset

            function clampSwipeDelta(deltaX) {
              if (notifWindow.isRight)
                return Math.max(0, deltaX);
              if (notifWindow.isLeft)
                return Math.min(0, deltaX);
              return deltaX;
            }

            function clampVerticalSwipeDelta(deltaY) {
              if (notifWindow.isBottom)
                return Math.max(0, deltaY);
              if (notifWindow.isTop)
                return Math.min(0, deltaY);
              return deltaY;
            }

            // Animation setup
            function triggerEntryAnimation() {
              reboundTimer.stop();
              animInDelayTimer.stop();
              removalTimer.stop();
              resumeTimer.stop();
              isRemoving = false;
              isHovered = false;
              isSwiping = false;
              swipeOffset = 0;
              swipeOffsetY = 0;
              if (Settings.data.general.animationDisabled) {
                slideOffset = 0;
                scaleValue = 1.0;
                opacityValue = 1.0;
                return;
              }

              slideOffset = slideInOffset;
              scaleValue = 0.8;
              opacityValue = 0.0;
              animInDelayTimer.interval = animationDelay;
              animInDelayTimer.start();
            }

            Component.onCompleted: triggerEntryAnimation()

            onNotificationIdChanged: triggerEntryAnimation()

            Timer {
              id: animInDelayTimer
              interval: 0
              repeat: false
              onTriggered: {
                if (card.isRemoving)
                  return;
                slideOffset = 0;
                scaleValue = 1.0;
                opacityValue = 1.0;
              }
            }

            function animateOut() {
              if (isRemoving)
                return;
              reboundTimer.stop();
              animInDelayTimer.stop();
              resumeTimer.stop();
              isRemoving = true;
              isSwiping = false;
              swipeOffset = 0;
              swipeOffsetY = 0;
              if (!Settings.data.general.animationDisabled) {
                slideOffset = slideOutOffset;
                scaleValue = 0.8;
                opacityValue = 0.0;
              }
            }

            function dismissBySwipe() {
              if (isRemoving)
                return;
              reboundTimer.stop();
              animInDelayTimer.stop();
              resumeTimer.stop();
              isRemoving = true;
              isSwiping = false;
              if (!Settings.data.general.animationDisabled) {
                if (useVerticalSwipe) {
                  swipeOffset = 0;
                  swipeOffsetY = swipeOffsetY >= 0 ? cardBackground.height + Style.marginXL : -cardBackground.height - Style.marginXL;
                } else {
                  swipeOffset = swipeOffset >= 0 ? cardBackground.width + Style.marginXL : -cardBackground.width - Style.marginXL;
                  swipeOffsetY = 0;
                }
                scaleValue = 0.8;
                opacityValue = 0.0;
              } else {
                swipeOffset = 0;
                swipeOffsetY = 0;
              }
            }

            function dismissByMaterialThrow() {
              if (isRemoving)
                return;
              reboundTimer.stop();
              animInDelayTimer.stop();
              resumeTimer.stop();
              isRemoving = true;
              isSwiping = false;
              if (!Settings.data.general.animationDisabled) {
                materialThrowAnimation.start();
                scaleValue = 0.94;
                opacityValue = 0;
              }
            }

            ParallelAnimation {
              id: materialThrowAnimation
              NumberAnimation {
                target: card
                property: "swipeOffset"
                to: Math.sign(card.rawDragX) * card.dragBound(card.rawDragX, true)
                duration: Style.animationFast
                easing.type: Easing.OutCubic
              }
              NumberAnimation {
                target: card
                property: "swipeOffsetY"
                to: Math.sign(card.rawDragY) * card.dragBound(card.rawDragY, false)
                duration: Style.animationFast
                easing.type: Easing.OutCubic
              }
            }

            function runAction(actionId, isDismissed) {
              if (!isDismissed) {
                if (NotificationService.invokeActionAndSuppressClose(notificationId, actionId))
                  card.animateOut();
              } else {
                if (Settings.data.notifications.clearDismissed)
                  NotificationService.removeFromHistory(notificationId);
                card.animateOut();
              }
            }

            Timer {
              id: removalTimer
              interval: Settings.data.general.animationDisabled ? 0 : Style.animationSlow
              repeat: false
              onTriggered: {
                NotificationService.dismissPopup(notificationId);
              }
            }

            onIsRemovingChanged: {
              if (isRemoving) {
                removalTimer.start();
              }
            }

            Behavior on scale {
              enabled: !Settings.data.general.animationDisabled
              SpringAnimation {
                spring: 3
                damping: 0.4
                epsilon: 0.01
                mass: 0.8
              }
            }

            Behavior on opacity {
              enabled: !Settings.data.general.animationDisabled
              NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
              }
            }

            Behavior on slideOffset {
              enabled: !Settings.data.general.animationDisabled
              SpringAnimation {
                spring: 2.5
                damping: 0.3
                epsilon: 0.01
                mass: 0.6
              }
            }

            Behavior on swipeOffset {
              enabled: !notifWindow.material && !Settings.data.general.animationDisabled && !card.isSwiping
              NumberAnimation {
                duration: Style.animationFast
                easing.type: Easing.OutCubic
              }
            }

            Behavior on swipeOffsetY {
              enabled: !notifWindow.material && !Settings.data.general.animationDisabled && !card.isSwiping
              NumberAnimation {
                duration: Style.animationFast
                easing.type: Easing.OutCubic
              }
            }

            function rebound() {
              if (Settings.data.general.animationDisabled) {
                swipeOffset = 0;
                swipeOffsetY = 0;
                return;
              }
              velocityX *= 0.16;
              velocityY *= 0.16;
              springTime = Date.now();
              reboundTimer.start();
            }

            Timer {
              id: reboundTimer
              interval: 16
              repeat: true
              onTriggered: {
                const now = Date.now();
                const elapsed = now - card.springTime;
                card.springTime = now;
                const x = NotificationMotion.springStep(card.swipeOffset, card.velocityX, elapsed, card.dragLimit, Settings.data.general.animationDisabled, {
                                                          negative: card.dragBound(-1, true),
                                                          positive: card.dragBound(1, true)
                                                        });
                const y = NotificationMotion.springStep(card.swipeOffsetY, card.velocityY, elapsed, card.dragLimit, Settings.data.general.animationDisabled, {
                                                          negative: card.dragBound(-1, false),
                                                          positive: card.dragBound(1, false)
                                                        });
                card.swipeOffset = x.position;
                card.swipeOffsetY = y.position;
                card.velocityX = x.velocity;
                card.velocityY = y.velocity;
                if (x.settled && y.settled)
                  stop();
              }
            }

            // Sub item with the right dimensions, really usefull for the
            // HoverHandler: card items are overlapping because of the
            // negative spacing of notificationStack.
            Item {
              id: displayedCard

              anchors.fill: parent
              anchors.margins: notifWindow.shadowPadding

              HoverHandler {
                onHoveredChanged: {
                  isHovered = hovered;
                  if (isHovered) {
                    resumeTimer.stop();
                    NotificationService.pauseTimeout(notificationId);
                  } else {
                    resumeTimer.start();
                  }
                }
              }

              Timer {
                id: resumeTimer
                interval: 50
                repeat: false
                onTriggered: {
                  if (NotificationMotion.shouldResumeTimeout(isHovered, cardDragArea.pressed)) {
                    NotificationService.resumeTimeout(notificationId);
                  }
                }
              }

              // Right-click to dismiss
              MouseArea {
                id: cardDragArea
                anchors.fill: cardBackground
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                onPressed: mouse => {
                  if (mouse.button === Qt.LeftButton) {
                    const globalPoint = cardDragArea.mapToGlobal(mouse.x, mouse.y);
                    reboundTimer.stop();
                    card.rawDragX = 0;
                    card.rawDragY = 0;
                    card.velocityX = 0;
                    card.velocityY = 0;
                    card.sampleTime = Date.now();
                    NotificationService.pauseTimeout(notificationId);
                    card.pressGlobalX = globalPoint.x;
                    card.pressGlobalY = globalPoint.y;
                    card.isSwiping = false;
                    card.suppressClick = false;
                  }
                }
                onPositionChanged: mouse => {
                  if (!(mouse.buttons & Qt.LeftButton) || card.isRemoving)
                    return;
                  const globalPoint = cardDragArea.mapToGlobal(mouse.x, mouse.y);
                  const rawDeltaX = globalPoint.x - card.pressGlobalX;
                  const rawDeltaY = globalPoint.y - card.pressGlobalY;
                  if (notifWindow.material) {
                    const now = Date.now();
                    card.velocityX = NotificationMotion.sampleVelocity(card.velocityX, rawDeltaX - card.rawDragX, now - card.sampleTime);
                    card.velocityY = NotificationMotion.sampleVelocity(card.velocityY, rawDeltaY - card.rawDragY, now - card.sampleTime);
                    card.rawDragX = rawDeltaX;
                    card.rawDragY = rawDeltaY;
                    card.sampleTime = now;
                    if (!card.isSwiping && Math.hypot(rawDeltaX, rawDeltaY) < card.swipeStartThreshold)
                      return;
                    card.isSwiping = true;
                    if (!Settings.data.general.animationDisabled) {
                      card.swipeOffset = NotificationMotion.dragOffset(rawDeltaX, card.dragBound(rawDeltaX, true));
                      card.swipeOffsetY = NotificationMotion.dragOffset(rawDeltaY, card.dragBound(rawDeltaY, false));
                    }
                    return;
                  }
                  const deltaX = card.clampSwipeDelta(rawDeltaX);
                  const deltaY = card.clampVerticalSwipeDelta(rawDeltaY);
                  if (!card.isSwiping) {
                    if (card.useVerticalSwipe) {
                      if (Math.abs(deltaY) < card.swipeStartThreshold)
                        return;
                      card.isSwiping = true;
                    } else {
                      if (Math.abs(deltaX) < card.swipeStartThreshold)
                        return;
                      card.isSwiping = true;
                    }
                  }
                  if (card.useVerticalSwipe) {
                    card.swipeOffset = 0;
                    card.swipeOffsetY = deltaY;
                  } else {
                    card.swipeOffset = deltaX;
                    card.swipeOffsetY = 0;
                  }
                }
                onReleased: mouse => {
                  if (mouse.button === Qt.RightButton) {
                    card.animateOut();
                    if (Settings.data.notifications.clearDismissed) {
                      NotificationService.removeFromHistory(notificationId);
                    }
                    return;
                  }

                  if (mouse.button !== Qt.LeftButton)
                    return;

                  if (card.isSwiping) {
                    if (notifWindow.material) {
                      // A held card is no longer a flick, even if the last move was fast.
                      const fresh = Date.now() - card.sampleTime <= 120;
                      if (NotificationMotion.shouldDismiss(card.rawDragX, card.rawDragY, fresh ? card.velocityX : 0, fresh ? card.velocityY : 0, cardBackground.width, cardBackground.height)) {
                        card.dismissByMaterialThrow();
                        if (Settings.data.notifications.clearDismissed)
                          NotificationService.removeFromHistory(notificationId);
                      } else {
                        card.rebound();
                        resumeTimer.restart();
                      }
                      card.suppressClick = true;
                      card.isSwiping = false;
                      return;
                    }
                    const dismissDistance = card.useVerticalSwipe ? Math.abs(card.swipeOffsetY) : Math.abs(card.swipeOffset);
                    const threshold = card.useVerticalSwipe ? card.verticalSwipeDismissThreshold : card.swipeDismissThreshold;
                    if (dismissDistance >= threshold) {
                      card.dismissBySwipe();
                      if (Settings.data.notifications.clearDismissed) {
                        NotificationService.removeFromHistory(notificationId);
                      }
                    } else {
                      card.swipeOffset = 0;
                      card.swipeOffsetY = 0;
                    }
                    card.suppressClick = true;
                    card.isSwiping = false;
                    return;
                  }

                  if (card.suppressClick)
                    return;

                  var actions = model.actionsJson ? JSON.parse(model.actionsJson) : [];
                  var hasDefault = actions.some(function (a) {
                    return a.identifier === "default";
                  });
                  if (hasDefault && NotificationService.invokeActionAndSuppressClose(notificationId, "default")) {
                    card.animateOut();
                  } else {
                    // Without a default action, or if invoking it fails,
                    // the best fallback is focusing the sender window by app identity.
                    NotificationService.focusSenderWindow(model.appName);
                    card.animateOut();
                  }
                }
                onCanceled: {
                  card.isSwiping = false;
                  card.swipeOffset = 0;
                  card.swipeOffsetY = 0;
                  resumeTimer.restart();
                }
              }

              // Background with border
              Rectangle {
                id: cardBackground
                anchors.fill: parent
                radius: notifWindow.material ? Math.round(28 * Style.uiScaleRatio) : Style.radiusL
                border.color: Qt.alpha(Color.mOutline, Color.adaptiveOpacity(Settings.data.notifications.backgroundOpacity) || 1.0)
                border.width: notifWindow.material ? 0 : Style.borderS
                color: Qt.alpha(notifWindow.material ? Color.mSurfaceVariant : Color.mSurface, Color.adaptiveOpacity(Settings.data.notifications.backgroundOpacity) || 1.0)

                // Progress bar
                Rectangle {
                  anchors.top: parent.top
                  anchors.left: parent.left
                  anchors.right: parent.right
                  height: notifWindow.material ? 3 : 2
                  anchors.topMargin: notifWindow.material ? Style.marginS : 0
                  color: "transparent"

                  Rectangle {
                    id: progressBar
                    readonly property real progressWidth: cardBackground.width - (2 * cardBackground.radius)
                    height: parent.height
                    x: cardBackground.radius + (progressWidth * (1 - model.progress)) / 2
                    width: progressWidth * model.progress

                    color: {
                      var baseColor = model.urgency === 2 ? Color.mError : model.urgency === 0 ? Color.mOnSurface : Color.mPrimary;
                      return Qt.alpha(baseColor, Color.adaptiveOpacity(Settings.data.notifications.backgroundOpacity) || 1.0);
                    }

                    antialiasing: true

                    Behavior on width {
                      enabled: !card.isRemoving
                      NumberAnimation {
                        duration: 100
                        easing.type: Easing.Linear
                      }
                    }

                    Behavior on x {
                      enabled: !card.isRemoving
                      NumberAnimation {
                        duration: 100
                        easing.type: Easing.Linear
                      }
                    }
                  }
                }
              }

              NDropShadow {
                anchors.fill: cardBackground
                source: cardBackground
                autoPaddingEnabled: true
              }

              Loader {
                id: notificationContentLoader
                source: Style.surfaceUrl("notificationContent")
                anchors.left: cardBackground.left
                anchors.right: cardBackground.right
                anchors.top: cardBackground.top
                anchors.margins: notifWindow.material ? Style.marginL : 0
                onLoaded: {
                  item.notificationData = Qt.binding(() => card.notificationData);
                  item.compact = Qt.binding(() => notifWindow.isCompact);
                }
              }

              Connections {
                target: notificationContentLoader.item
                function onActionRequested(identifier) {
                  card.runAction(identifier, false);
                }
                function onDismissRequested() {
                  card.runAction("", true);
                }
              }
            }
          }
        }
      }
    }
  }
}
