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

  // Local state
  property string valueDisplayMode: widgetData.displayMode !== undefined ? widgetData.displayMode : widgetMetadata.displayMode
  property string valueIconColor: widgetData.iconColor !== undefined ? widgetData.iconColor : widgetMetadata.iconColor
  property string valueTextColor: widgetData.textColor !== undefined ? widgetData.textColor : widgetMetadata.textColor
  property bool valueHideWhenOffline: widgetData.hideWhenOffline !== undefined ? widgetData.hideWhenOffline : widgetMetadata.hideWhenOffline
  property bool valueLiquid: widgetData.liquid !== undefined ? widgetData.liquid : widgetMetadata.liquid
  property bool valueShowUnread: widgetData.showUnread !== undefined ? widgetData.showUnread : widgetMetadata.showUnread

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.displayMode = valueDisplayMode;
    settings.iconColor = valueIconColor;
    settings.textColor = valueTextColor;
    settings.hideWhenOffline = valueHideWhenOffline;
    settings.liquid = valueLiquid;
    settings.showUnread = valueShowUnread;
    settingsChanged(settings);
  }

  NComboBox {
    label: I18n.tr("common.display-mode")
    description: I18n.tr("bar.kdeconnect.display-mode-description")
    minimumWidth: 200
    model: [
      {
        "key": "onhover",
        "name": I18n.tr("display-modes.on-hover")
      },
      {
        "key": "alwaysShow",
        "name": I18n.tr("display-modes.always-show")
      },
      {
        "key": "alwaysHide",
        "name": I18n.tr("display-modes.always-hide")
      }
    ]
    currentKey: root.valueDisplayMode
    onSelected: key => {
      root.valueDisplayMode = key;
      saveSettings();
    }
    defaultValue: widgetMetadata.displayMode
  }

  NToggle {
    label: I18n.tr("bar.kdeconnect.liquid-label")
    description: I18n.tr("bar.kdeconnect.liquid-description")
    checked: root.valueLiquid
    onToggled: checked => {
      root.valueLiquid = checked;
      saveSettings();
    }
    defaultValue: widgetMetadata.liquid
  }

  NToggle {
    label: I18n.tr("bar.kdeconnect.hide-when-offline-label")
    description: I18n.tr("bar.kdeconnect.hide-when-offline-description")
    checked: root.valueHideWhenOffline
    onToggled: checked => {
      root.valueHideWhenOffline = checked;
      saveSettings();
    }
    defaultValue: widgetMetadata.hideWhenOffline
  }

  NToggle {
    label: I18n.tr("bar.kdeconnect.show-unread-label")
    description: I18n.tr("bar.kdeconnect.show-unread-description")
    checked: root.valueShowUnread
    onToggled: checked => {
      root.valueShowUnread = checked;
      saveSettings();
    }
    defaultValue: widgetMetadata.showUnread
  }

  NColorChoice {
    label: I18n.tr("common.select-icon-color")
    currentKey: valueIconColor
    onSelected: key => {
      valueIconColor = key;
      saveSettings();
    }
    defaultValue: widgetMetadata.iconColor
  }

  NColorChoice {
    currentKey: valueTextColor
    onSelected: key => {
      valueTextColor = key;
      saveSettings();
    }
    defaultValue: widgetMetadata.textColor
  }
}
