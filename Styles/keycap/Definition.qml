import QtQuick

// Keycap: bold sticker and keycap look. Every surface is an ink outline, a thin
// cream ring, a fill and a hard shadow straight down; things pop in with an
// overshoot. Panels use the shared Material layouts, drawn with this folder's
// control skins; bar widgets get their own faces from `barViews` (Bar/).
QtObject {
  readonly property string labelKey: "options.ui-style.keycap"
  // Shared helpers of this style's skins and faces; Style.kit is its live instance
  readonly property string kit: "Styles/keycap/Kit.qml"
  // Appearance defaults for this style's TOML profile (Helpers/UiStyleSettings.js)
  readonly property var settingsDefaults: ({
                                             "ui": {
                                               "fontDefault": "Google Sans Flex",
                                               "boxBorderEnabled": true,
                                               "boxBorderWidth": 2,
                                               "panelBackgroundOpacity": 1.0,
                                               "frostedGlass": false
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
                                  "launcher": "Styles/keycap/LauncherView.qml",
                                  "sessionMenu": "Styles/keycap/SessionMenuView.qml",
                                  "lyrics": "Styles/keycap/LyricsView.qml"
                                })
  // Bar widget faces, keyed by the name a bar widget passes as `faceView`.
  // "Plate" is the plain keycap used by widgets without a face of their own.
  readonly property var barViews: ({
                                     "Plate": "Styles/keycap/Bar/PlateFace.qml",
                                     "ActiveWindow": "Styles/keycap/Bar/ActiveWindowFace.qml",
                                     "AudioVisualizer": "Styles/keycap/Bar/AudioVisualizerFace.qml",
                                     "Battery": "Styles/keycap/Bar/BatteryFace.qml",
                                     "Bluetooth": "Styles/keycap/Bar/BluetoothFace.qml",
                                     "Brightness": "Styles/keycap/Bar/BrightnessFace.qml",
                                     "Clock": "Styles/keycap/Bar/ClockFace.qml",
                                     "ControlCenter": "Styles/keycap/Bar/ControlCenterFace.qml",
                                     "DarkMode": "Styles/keycap/Bar/DarkModeFace.qml",
                                     "EcoMode": "Styles/keycap/Bar/EcoModeFace.qml",
                                     "KdeConnect": "Styles/keycap/Bar/KdeConnectFace.qml",
                                     "KeepAwake": "Styles/keycap/Bar/KeepAwakeFace.qml",
                                     "KeyboardLayout": "Styles/keycap/Bar/KeyboardLayoutFace.qml",
                                     "Launcher": "Styles/keycap/Bar/LauncherFace.qml",
                                     "LockKeys": "Styles/keycap/Bar/LockKeysFace.qml",
                                     "MediaMini": "Styles/keycap/Bar/MediaMiniFace.qml",
                                     "Microphone": "Styles/keycap/Bar/MicrophoneFace.qml",
                                     "ModelUsage": "Styles/keycap/Bar/ModelUsageFace.qml",
                                     "Network": "Styles/keycap/Bar/NetworkFace.qml",
                                     "NightLight": "Styles/keycap/Bar/NightLightFace.qml",
                                     "NotificationHistory": "Styles/keycap/Bar/NotificationHistoryFace.qml",
                                     "PowerProfile": "Styles/keycap/Bar/PowerProfileFace.qml",
                                     "SessionMenu": "Styles/keycap/Bar/SessionMenuFace.qml",
                                     "Settings": "Styles/keycap/Bar/SettingsFace.qml",
                                     "SystemMonitor": "Styles/keycap/Bar/SystemMonitorFace.qml",
                                     "Taskbar": "Styles/keycap/Bar/TaskbarFace.qml",
                                     "Volume": "Styles/keycap/Bar/VolumeFace.qml",
                                     "VPN": "Styles/keycap/Bar/VpnFace.qml",
                                     "Weather": "Styles/keycap/Bar/WeatherFace.qml",
                                     "Workspace": "Styles/keycap/Bar/WorkspaceFace.qml",
                                     "WorkspaceKey": "Styles/keycap/Bar/WorkspaceKeyFace.qml"
                                   })
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
                                     "Regular": 500,
                                     "Medium": 600,
                                     "SemiBold": 700,
                                     "Bold": 800
                                   },
                                   "fontFamily": "Google Sans Flex",
                                   // Tried in order when the preset font is not installed; Rubik is bundled.
                                   "fontFallbacks": ["Google Sans Flex", "Google Sans", "Rubik"],
                                   "fixedFontFamily": "monospace",
                                   "radii": {
                                     "XXXS": 4,
                                     "XXS": 6,
                                     "XS": 10,
                                     "S": 14,
                                     "M": 18,
                                     "L": 22
                                   },
                                   "inputRadii": {
                                     "XXXS": 4,
                                     "XXS": 6,
                                     "XS": 9,
                                     "S": 12,
                                     "M": 14,
                                     "L": 18
                                   },
                                   "borders": {
                                     "S": 2,
                                     "M": 2,
                                     "L": 3
                                   },
                                   "margins": {
                                     "XXXS": 1,
                                     "XXS": 2,
                                     "XS": 4,
                                     "S": 7,
                                     "M": 10,
                                     "L": 14,
                                     "XL": 20
                                   },
                                   "animations": {
                                     "Faster": 80,
                                     "Fast": 160,
                                     "Normal": 280,
                                     "Slow": 420,
                                     "Slowest": 700
                                   },
                                   "baseWidgetSize": 33,
                                   "sliderWidth": 200,
                                   // Round knob on an outlined track
                                   "slider": {
                                     "shape": "knob",
                                     "heightRatio": 0.7,
                                     "trackRatio": 0.45,
                                     "cutoutRatio": 0,
                                     "trackOpacity": 1,
                                     "gradientDarkening": 1
                                   },
                                   // Fixed handle sliding along a track
                                   "toggle": {
                                     "shape": "track",
                                     "sizeRatio": 0.8,
                                     "widthRatio": 0.9,
                                     "heightRatio": 0.5,
                                     "handleRatio": 0.36,
                                     "handleInset": 4
                                   },
                                   // Shapes of the Material panel layouts Keycap draws on
                                   "buttonGroup": {
                                     "gap": 4,
                                     "innerRadius": 8
                                   },
                                   "expandable": {
                                     "gap": 4,
                                     "outerRadius": 22,
                                     "innerRadius": 6
                                   },
                                   "field": {
                                     "radius": 12,
                                     "focusBorderWidth": 2
                                   },
                                   "weather": {
                                     "radius": 22,
                                     "tileRadius": 18,
                                     "cookieLobes": 9,
                                     "cookieDepth": 0.1
                                   },
                                   "menu": {
                                     "radius": 14,
                                     "padding": 8
                                   },
                                   // Popups and cards are solid: their hard shadow must not show through
                                   // Material state layers (NMaterialStateLayer) on shared layouts
                                   "stateLayers": false,
                                   "surfaces": {
                                     "opaque": true
                                   },
                                   // Bar faces: shadow depth of a face at rest, and in the bar, limited
                                   // by the slack around the capsule (px at scale 1)
                                   "faces": {
                                     "depth": 3,
                                     "barDepth": 2
                                   },
                                   "keycap": {
                                     // Hard shadow depth at rest and while pressed, and the hover lift (px at scale 1).
                                     "depth": 3,
                                     "pressedDepth": 1,
                                     "hoverLift": 1,
                                     "outline": 2,
                                     "ring": 1,
                                     "cream": "#fff3dc",
                                     // Easing.OutBack overshoot for release and pop-in animations.
                                     "overshoot": 2.2,
                                     "popOvershoot": 1.6,
                                     // Maximum sticker tilt in degrees.
                                     "tilt": 4
                                   },
                                   "radialMenu": {
                                     "shape": "chunky",
                                     "borderWidth": 2,
                                     "shadowY": 3,
                                     "keylineWidth": 1,
                                     "hoverLift": 3,
                                     "pressDepth": 2,
                                     "tilt": 4,
                                     "colors": {
                                       "keyline": "#fff3dc"
                                     }
                                   }
                                 })
}
