import QtQuick

// Material 3 Expressive: tonal fills, state layers and connected button groups.
// The shared panel layouts are Material's; this folder holds its control skins.
// A style folder is found by Commons/UiStyleRegistry.qml; Tests/python/test_style_folders.py
// lists what every style folder must contain.
QtObject {
  readonly property string labelKey: "options.ui-style.material"
  // No shared helpers of its own
  readonly property string kit: ""
  // Appearance defaults for this style's TOML profile (Helpers/UiStyleSettings.js)
  readonly property var settingsDefaults: ({
                                             "ui": {
                                               "fontDefault": "Roboto",
                                               "boxBorderEnabled": false,
                                               "panelBackgroundOpacity": 1.0,
                                               "frostedGlass": true
                                             }
                                           })
  // Surface layouts, relative to the shell directory
  readonly property var views: ({
                                  "controlCenter": "Modules/Panels/ControlCenter/MaterialControlCenter.qml",
                                  "mediaCard": "Modules/Cards/MaterialMediaCard.qml",
                                  "mediaPlayer": "Modules/Panels/Media/MaterialMediaPlayerContent.qml",
                                  "osd": "Modules/OSD/MaterialOsdContent.qml",
                                  "notificationContent": "Modules/Notification/MaterialNotificationContent.qml",
                                  "kdeConnectHome": "Modules/Panels/KdeConnect/MaterialKdeConnectHome.qml",
                                  "launcher": "Modules/Panels/Launcher/MaterialLauncherView.qml",
                                  "sessionMenu": "Modules/Panels/SessionMenu/MaterialSessionMenuView.qml"
                                })
  // Bar widgets keep the shared look
  readonly property var barViews: ({})
  readonly property var tokens: ({
                                   "fontSizes": {
                                     "XXS": 8,
                                     "XS": 9,
                                     "S": 10,
                                     "M": 11,
                                     "L": 14,
                                     "XL": 17,
                                     "XXL": 20,
                                     "XXXL": 26
                                   },
                                   "fontWeights": {
                                     "Regular": 400,
                                     "Medium": 500,
                                     "SemiBold": 500,
                                     "Bold": 700
                                   },
                                   "fontFamily": "Roboto",
                                   "fixedFontFamily": "monospace",
                                   "radii": {
                                     "XXXS": 4,
                                     "XXS": 8,
                                     "XS": 12,
                                     "S": 16,
                                     "M": 24,
                                     "L": 28
                                   },
                                   "inputRadii": {
                                     "XXXS": 4,
                                     "XXS": 8,
                                     "XS": 12,
                                     "S": 20,
                                     "M": 12,
                                     "L": 28
                                   },
                                   "borders": {
                                     "S": 1,
                                     "M": 2,
                                     "L": 3
                                   },
                                   "margins": {
                                     "XXXS": 1,
                                     "XXS": 2,
                                     "XS": 4,
                                     "S": 8,
                                     "M": 12,
                                     "L": 16,
                                     "XL": 24
                                   },
                                   "animations": {
                                     "Faster": 90,
                                     "Fast": 200,
                                     "Normal": 350,
                                     "Slow": 500,
                                     "Slowest": 800
                                   },
                                   "baseWidgetSize": 33,
                                   "sliderWidth": 200,
                                   // Split track around a slim vertical handle
                                   "slider": {
                                     "shape": "split",
                                     "heightRatio": 0.7,
                                     "trackRatio": 0.4,
                                     "cutoutRatio": 0.1,
                                     "trackOpacity": 1,
                                     "gradientDarkening": 1,
                                     "hitWidth": 40,
                                     "handleHeight": 44,
                                     "handleWidth": 4,
                                     "pressedHandleWidth": 2,
                                     "trackHeight": 16,
                                     "gap": 12
                                   },
                                   // Pill switch whose handle grows when on and while pressed
                                   "toggle": {
                                     "shape": "pill",
                                     "sizeRatio": 0.8,
                                     "width": 52,
                                     "height": 32,
                                     "handleOff": 16,
                                     "handleOn": 24,
                                     "handlePressed": 28,
                                     "border": 2
                                   },
                                   "buttonGroup": {
                                     "gap": 2,
                                     "innerRadius": 8
                                   },
                                   "expandable": {
                                     "gap": 2,
                                     "outerRadius": 24,
                                     "innerRadius": 4
                                   },
                                   "field": {
                                     "radius": 12,
                                     "focusBorderWidth": 1
                                   },
                                   "weather": {
                                     "radius": 28,
                                     "tileRadius": 24,
                                     "cookieLobes": 9,
                                     "cookieDepth": 0.1
                                   },
                                   "menu": {
                                     "radius": 16,
                                     "padding": 8
                                   },
                                   // Popups and cards: translucent surfaces with soft shadows
                                   // Material state layers (NMaterialStateLayer) on shared layouts
                                   "stateLayers": true,
                                   "surfaces": {
                                     "opaque": false
                                   },
                                   "frostedGlass": {
                                     "panelOpacity": 0.85,
                                     "surfaceOpacity": 0.7
                                   },
                                   // Desktop radial menu look; the shape preset fills the rest (Helpers/RadialMenu.js)
                                   "radialMenu": {
                                     "shape": "segment",
                                     "cornerRadius": 10,
                                     "fillOpacity": 0.96
                                   }
                                 })
}
