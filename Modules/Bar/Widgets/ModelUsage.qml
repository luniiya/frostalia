import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  // Explicit screenName property ensures reactive binding when screen changes
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0 && screenName) {
      var widgets = Settings.getBarWidgetsForScreen(screenName, section)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property string barPosition: Settings.getBarPositionForScreen(screenName, section)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName, section)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName, section)

  readonly property string displayMode: widgetSettings.displayMode !== undefined ? widgetSettings.displayMode : widgetMetadata.displayMode
  readonly property int cycleIntervalSec: widgetSettings.cycleIntervalSec !== undefined ? widgetSettings.cycleIntervalSec : widgetMetadata.cycleIntervalSec
  readonly property string metric: widgetSettings.metric !== undefined ? widgetSettings.metric : widgetMetadata.metric

  // Which enabled provider is shown; advances in "cycle" mode
  property int cycleIndex: 0
  readonly property var providers: ModelUsageService.enabledProviders
  readonly property var provider: providers.length > 0 ? providers[ModelUsageLogic.clampIndex(cycleIndex, providers.length)] : null

  readonly property string displayText: ModelUsageLogic.barText(provider, metric)

  readonly property string tooltipText: {
    if (!provider)
      return I18n.tr("model-usage.no-providers");
    let tip = I18n.tr("model-usage.tooltip", {
                        "provider": provider.providerName,
                        "prompts": provider.todayPrompts,
                        "sessions": provider.todaySessions,
                        "tokens": ModelUsageLogic.formatTokenCount(provider.todayTotalTokens)
                      });
    if (provider.primary.percent >= 0) {
      tip += "\n" + ModelUsageService.limitLabel(provider.primary) + ": " + Math.round(provider.primary.percent * 100) + "%";
      if (provider.secondary.percent >= 0)
        tip += "\n" + ModelUsageService.limitLabel(provider.secondary) + ": " + Math.round(provider.secondary.percent * 100) + "%";
    } else if (provider.statusText !== "") {
      tip += "\n" + provider.statusText;
    }
    return tip;
  }

  readonly property real contentWidth: isBarVertical ? capsuleHeight : content.implicitWidth + Style.margin2M
  readonly property real contentHeight: isBarVertical ? content.implicitHeight + Style.margin2M : capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Timer {
    interval: Math.max(2, root.cycleIntervalSec) * 1000
    running: root.displayMode === "cycle" && root.providers.length > 1
    repeat: true
    onTriggered: root.cycleIndex = (root.cycleIndex + 1) % root.providers.length
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("common.refresh"),
        "action": "refresh",
        "icon": "refresh"
      },
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      }
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "refresh") {
        ModelUsageService.refresh();
      } else if (action === "widget-settings") {
        BarService.openWidgetSettings(screen, section, sectionWidgetIndex, widgetId, widgetSettings);
      }
    }
  }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusL
    color: Style.widgetBackground(root.section, mouseArea.containsMouse ? Color.mHover : Style.capsuleColor)
    border.color: Style.widgetBorder(root.section, Style.capsuleBorderColor)
    border.width: Style.capsuleBorderWidth

    GridLayout {
      id: content
      anchors.centerIn: parent
      flow: root.isBarVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
      rows: root.isBarVertical ? 2 : 1
      columns: root.isBarVertical ? 1 : 2
      rowSpacing: Style.marginXS
      columnSpacing: Style.marginS

      NIcon {
        icon: root.provider ? root.provider.providerIcon : "ai"
        pointSize: root.barFontSize
        applyUiScale: false
        color: mouseArea.containsMouse ? Color.mOnHover : Color.mPrimary
        Layout.alignment: Qt.AlignCenter
      }

      NText {
        text: root.displayText
        pointSize: root.barFontSize
        applyUiScale: false
        font.weight: Style.fontWeightSemiBold
        color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
        Layout.alignment: Qt.AlignCenter
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
      TooltipService.hide();
      if (mouse.button === Qt.LeftButton) {
        PanelService.getPanel("modelUsagePanel", screen)?.toggle(root);
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }
    onEntered: TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screenName, root.section))
    onExited: TooltipService.hide()
  }
}
