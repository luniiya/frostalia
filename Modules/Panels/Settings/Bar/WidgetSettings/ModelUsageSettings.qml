import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var screen: null
  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  property string valueMetric: widgetData.metric !== undefined ? widgetData.metric : widgetMetadata.metric
  property string valueDisplayMode: widgetData.displayMode !== undefined ? widgetData.displayMode : widgetMetadata.displayMode
  property int valueCycleIntervalSec: widgetData.cycleIntervalSec !== undefined ? widgetData.cycleIntervalSec : widgetMetadata.cycleIntervalSec

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.metric = valueMetric;
    settings.displayMode = valueDisplayMode;
    settings.cycleIntervalSec = valueCycleIntervalSec;
    settingsChanged(settings);
  }

  NComboBox {
    label: I18n.tr("bar.model-usage.metric-label")
    description: I18n.tr("bar.model-usage.metric-description")
    minimumWidth: 200
    model: [
      {
        "key": "prompts",
        "name": I18n.tr("bar.model-usage.metric-prompts")
      },
      {
        "key": "tokens",
        "name": I18n.tr("bar.model-usage.metric-tokens")
      },
      {
        "key": "usage",
        "name": I18n.tr("bar.model-usage.metric-usage")
      }
    ]
    currentKey: root.valueMetric
    defaultValue: widgetMetadata.metric
    onSelected: key => {
      root.valueMetric = key;
      saveSettings();
    }
  }

  NComboBox {
    label: I18n.tr("bar.model-usage.display-mode-label")
    description: I18n.tr("bar.model-usage.display-mode-description")
    minimumWidth: 200
    model: [
      {
        "key": "active",
        "name": I18n.tr("bar.model-usage.display-mode-active")
      },
      {
        "key": "cycle",
        "name": I18n.tr("bar.model-usage.display-mode-cycle")
      }
    ]
    currentKey: root.valueDisplayMode
    defaultValue: widgetMetadata.displayMode
    onSelected: key => {
      root.valueDisplayMode = key;
      saveSettings();
    }
  }

  NSpinBox {
    visible: root.valueDisplayMode === "cycle"
    label: I18n.tr("bar.model-usage.cycle-interval-label")
    description: I18n.tr("bar.model-usage.cycle-interval-description")
    from: 2
    to: 60
    suffix: "s"
    value: root.valueCycleIntervalSec
    defaultValue: widgetMetadata.cycleIntervalSec
    onValueChanged: {
      root.valueCycleIntervalSec = value;
      saveSettings();
    }
  }
}
