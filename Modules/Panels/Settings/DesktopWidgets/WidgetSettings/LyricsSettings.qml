import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  property int valueWidth: widgetData.width !== undefined ? widgetData.width : widgetMetadata.width
  property string valueColorName: widgetData.colorName !== undefined ? widgetData.colorName : widgetMetadata.colorName
  property bool valueShowTrack: widgetData.showTrack !== undefined ? widgetData.showTrack : widgetMetadata.showTrack

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.width = valueWidth;
    settings.colorName = valueColorName;
    settings.showTrack = valueShowTrack;
    settingsChanged(settings);
  }

  NTextInput {
    Layout.fillWidth: true
    label: I18n.tr("common.width")
    description: I18n.tr("panels.desktop-widgets.lyrics-width-description")
    text: String(valueWidth)
    placeholderText: I18n.tr("placeholders.enter-width-pixels")
    inputMethodHints: Qt.ImhDigitsOnly
    onEditingFinished: {
      const parsed = parseInt(text);
      if (!isNaN(parsed) && parsed > 0) {
        valueWidth = parsed;
        saveSettings();
      } else {
        text = String(valueWidth);
      }
    }
    defaultValue: String(widgetMetadata.width)
  }

  NColorChoice {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.lyrics-color-label")
    description: I18n.tr("panels.desktop-widgets.lyrics-color-description")
    currentKey: valueColorName
    onSelected: key => {
      valueColorName = key;
      saveSettings();
    }
    defaultValue: widgetMetadata.colorName
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.desktop-widgets.lyrics-show-track-label")
    description: I18n.tr("panels.desktop-widgets.lyrics-show-track-description")
    checked: valueShowTrack
    onToggled: checked => {
      valueShowTrack = checked;
      saveSettings();
    }
    defaultValue: widgetMetadata.showTrack
  }
}
