.pragma library
.import "UiStyles.js" as UiStyles
.import "SettingsObject.js" as SettingsObject

// Only these appearance settings belong to a style. Scaling stays per host.
var defaults = {
  "general": {
    "dimmerOpacity": 0.2,
    "radiusRatio": 1.0,
    "iRadiusRatio": 1.0,
    "animationSpeed": 1.0,
    "animationDisabled": false,
    "enableShadows": true,
    "enableBlurBehind": true,
    "shadowDirection": "bottom_right",
    "shadowOffsetX": 2,
    "shadowOffsetY": 3,
    "allowPanelsOnScreenWithoutBar": true
  },
  "ui": {
    "fontDefault": "Rubik",
    "fontFixed": "",
    "tooltipsEnabled": true,
    "scrollbarAlwaysVisible": true,
    "boxBorderEnabled": true,
    "boxBorderWidth": 1,
    "boxBorderColor": "outline",
    "boxBorderBrightness": 0,
    "boxBorderOpacity": 100,
    "panelBackgroundOpacity": 0.93,
    "translucentWidgets": false,
    "frostedGlass": false,
    "panelsAttachedToBar": true,
    "settingsPanelSideBarCardStyle": false
  }
};

function forStyle(style) {
  return SettingsObject.resolve(defaults, UiStyles.definitions[UiStyles.resolveId(style)].settingsDefaults || {});
}

function defaultValue(style, path) {
  const parts = path.split(".");
  const values = forStyle(style);
  return parts.length === 2 && values[parts[0]] ? values[parts[0]][parts[1]] : undefined;
}

function configuration(directory) {
  const styles = {};
  for (const choice of UiStyles.choices())
    styles[choice.key] = forStyle(choice.key);
  return { directory: directory, default_style: UiStyles.defaultStyle, defaults: styles };
}
