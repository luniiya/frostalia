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
    "fontDefault": "Roboto",
    "fontFixed": "",
    "tooltipsEnabled": true,
    "scrollbarAlwaysVisible": true,
    "boxBorderEnabled": false,
    "boxBorderWidth": 1,
    "boxBorderColor": "outline",
    "boxBorderBrightness": 0,
    "boxBorderOpacity": 100,
    "panelBackgroundOpacity": 1.0,
    "translucentWidgets": false,
    "frostedGlass": true,
    "glassPanelOpacity": 0.85,
    "glassSurfaceOpacity": 0.7,
    "panelsAttachedToBar": true,
    "settingsPanelSideBarCardStyle": false
  }
};

// `definitions` is the style map of Commons/UiStyleRegistry.qml (id -> definition).
function forStyle(definitions, style) {
  const definition = UiStyles.definition(definitions, style);
  return SettingsObject.resolve(defaults, definition ? definition.settingsDefaults || {} : {});
}

function defaultValue(definitions, style, path) {
  const parts = path.split(".");
  const values = forStyle(definitions, style);
  return parts.length === 2 && values[parts[0]] ? values[parts[0]][parts[1]] : undefined;
}

function configuration(directory, definitions) {
  const styles = {};
  for (const choice of UiStyles.choices(definitions))
    styles[choice.key] = forStyle(definitions, choice.key);
  return { directory: directory, default_style: UiStyles.defaultStyle, defaults: styles };
}
