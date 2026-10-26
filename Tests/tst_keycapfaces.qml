import QtQuick
import QtTest
import "../Helpers/UiStyles.js" as UiStyles
import "../Widgets" as Widgets

// Loads every Keycap bar face with a stand-in kit and host, in both bar
// orientations and every interaction state, and fails on any QML warning.
TestCase {
  id: testCase
  name: "KeycapFaces"
  visible: true
  when: windowShown
  width: 400
  height: 200

  QtObject {
    id: kit
    property color cream: "#fff3dc"
    property color ink: "#141218"
    property color fill: "#3a3546"
    property color fillText: "#fff3dc"
    property color primary: "#a8c7fa"
    property color primaryText: "#062e6f"
    property color secondary: "#c2e7ff"
    property color secondaryText: "#003355"
    property color tertiary: "#ffb4ab"
    property color tertiaryText: "#5f1414"
    property color error: "#f2b8b5"
    property color errorText: "#601410"
    property color surface: "#1d1b20"
    property color surfaceText: "#e6e0e9"
    property color surfaceVariant: "#49454f"
    property color surfaceVariantText: "#cac4d0"
    property color hover: "#d0bcff"
    property color hoverText: "#381e72"
    property real depth: 3
    property real pressedDepth: 1
    property real hoverLift: 1
    property real outline: 2
    property real ring: 1
    property real radius: 18
    property real smallRadius: 10
    property real tiltMax: 4
    property real overshoot: 2.2
    property real popOvershoot: 1.6
    property bool animated: true
    property int fast: 160
    property int normal: 280
    property int slow: 420
    property string fontFamily: "Sans"
    property string fontFixed: "monospace"
    property int fontWeightBold: 800
    property string iconFamily: "Sans"

    function glyph(name) {
      return name ? "*" : "";
    }
    function ringFor(c) {
      return cream;
    }
    function readableOn(c) {
      return c.hslLightness > 0.5 ? ink : cream;
    }
    function mix(a, b, t) {
      return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }
  }

  Item {
    id: host
    property string icon: "volume"
    property rect iconRect: Qt.rect(35, 0, 25, 25)
    property real iconSize: 11
    property real buttonSize: 25
    property color colorFg: "#e6e0e9"
    property color colorBg: "#49454f"
    property color customBackgroundColor: "transparent"
    property var displayLines: ["14:05"]
    property bool isBarVertical: false
    property bool isVerticalBar: false
    property bool isVertical: false
    property real barFontSize: 9
    property color textColor: "#e6e0e9"
    property string displayFamily: "Sans"
  }

  Item {
    id: stage
    width: 120
    height: 40
  }

  readonly property var faceData: ({
                                     "level": 0.6,
                                     "muted": false,
                                     "connected": true,
                                     "enabled": true,
                                     "devices": 2,
                                     "active": true,
                                     "on": true,
                                     "count": 3,
                                     "showBadge": true,
                                     "dnd": false,
                                     "badgeColor": "#f2b8b5",
                                     "dark": true,
                                     "profile": "performance",
                                     "focused": true,
                                     "urgent": false,
                                     "occupied": true,
                                     "focusedColor": "#a8c7fa",
                                     "occupiedColor": "#c2e7ff",
                                     "emptyColor": "#cac4d0",
                                     "leds": [
                                       {
                                         "on": true
                                       },
                                       {
                                         "on": false
                                       }
                                     ],
                                     "round": false,
                                     "alert": false
                                   })

  function init() {
    failOnWarning(/.+/);
  }

  function faceNames() {
    return Object.keys(UiStyles.definitions.keycap.barViews);
  }

  function create(name, extra) {
    const component = Qt.createComponent(Qt.resolvedUrl("../" + UiStyles.barView("keycap", name)));
    compare(component.status, Component.Ready, name + ": " + component.errorString());
    const props = Object.assign({
                                  "kit": kit,
                                  "host": host,
                                  "width": 60,
                                  "height": 25,
                                  "depth": 2,
                                  "faceData": testCase.faceData
                                }, extra || {});
    const face = component.createObject(stage, props);
    verify(face !== null, name);
    return face;
  }

  function test_everyFaceLoadsInEveryState_data() {
    const rows = [];
    for (const name of faceNames()) {
      rows.push({
                  "tag": name + " horizontal",
                  "name": name,
                  "vertical": false
                });
      rows.push({
                  "tag": name + " vertical",
                  "name": name,
                  "vertical": true
                });
    }
    return rows;
  }

  function test_everyFaceLoadsInEveryState(data) {
    host.isBarVertical = data.vertical;
    host.isVerticalBar = data.vertical;
    host.isVertical = data.vertical;
    host.displayLines = data.vertical ? ["14", "05"] : ["14:05"];
    const face = create(data.name, data.vertical ? {
                                                     "width": 25,
                                                     "height": 60
                                                   } : {});
    try {
      verify(face.width > 0);
      face.hovered = true;
      wait(20);
      face.pressed = true;
      wait(20);
      face.pressed = false;
      face.hovered = false;
      face.faceData = Object.assign({}, testCase.faceData, {
                                      "muted": true,
                                      "count": 12,
                                      "focused": false,
                                      "occupied": false,
                                      "level": 0
                                    });
      host.displayLines = data.vertical ? ["14", "06"] : ["14:06"];
      face.bump();
      wait(40);
      verify(isFinite(face.sink));
    } finally {
      face.destroy();
      host.isBarVertical = false;
      host.isVerticalBar = false;
      host.isVertical = false;
      host.displayLines = ["14:05"];
    }
  }

  function test_keyFacesSinkWhilePressed_data() {
    return ["Plate", "Volume", "Microphone", "KeyboardLayout", "Weather", "VPN", "Settings"].map(name => ({
      "tag": name,
      "name": name
    }));
  }

    function test_keyFacesSinkWhilePressed(data) {
    const face = create(data.name, {
    "faceData": {}
  });
    try {
    const rest = face.sink;
    face.pressed = true;
    tryVerify(() => face.sink > rest, 1000, data.name + " sinks");
    face.pressed = false;
    tryVerify(() => Math.abs(face.sink - rest) < 0.01, 1000, data.name + " springs back");
  } finally {
    face.destroy();
  }
  }

    function test_volumeLatchesDownWhenMuted() {
    const face = create("Volume", {
    "faceData": {
    "level": 0.5,
    "muted": true
  }
  });
    try {
    tryVerify(() => face.sink > face.centerShift, 1000);
    compare(face.lit, 0);
    face.faceData = {
    "level": 0.5,
    "muted": false
  };
    compare(face.lit, 3);
  } finally {
    face.destroy();
  }
  }

    function test_clockSplitsIntoFlipCards() {
    host.displayLines = ["Mon 14:05"];
    const face = create("Clock");
    try {
    verify(face.ownsContent);
    compare(face.segments.map(s => s.text), ["Mon", " ", "14", ":", "05"]);
    verify(face.naturalWidth > 0);
  } finally {
    face.destroy();
    host.displayLines = ["14:05"];
  }
  }

    function test_notificationBadgeCountsUp() {
    const face = create("NotificationHistory", {
    "faceData": {
    "count": 0
  }
  });
    try {
    compare(face.label, "");
    face.faceData = {
    "count": 14
  };
    compare(face.label, "9+");
    verify(face.ownsIcon);
  } finally {
    face.destroy();
  }
  }

    function test_workspaceKeyKinds() {
    const face = create("WorkspaceKey", {
    "faceData": {
    "focused": false,
    "occupied": false
  }
  });
    try {
    compare(face.look.kind, "empty");
    face.faceData = {
    "occupied": true,
    "occupiedColor": "#123456"
  };
    compare(face.look.kind, "occupied");
    compare(face.keyColor, Qt.color("#123456"));
    face.faceData = {
    "focused": true,
    "urgent": true
  };
    compare(face.look.kind, "focused");
  } finally {
    face.destroy();
  }
  }

    Component {
    id: keycapComponent
    Widgets.NKeycap {
    width: 40
    height: 20
    depth: 3
    pressedDepth: 1
    hoverLift: 1
  }
  }

    function test_nkeycapSinksAndSpringsBack() {
    const key = createTemporaryObject(keycapComponent, stage);
    compare(key.sink, 0);
    key.hovered = true;
    compare(key.sink, -1);
    key.pressed = true;
    compare(key.sink, 2);
    tryCompare(key, "faceY", 2, 1000);
    key.pressed = false;
    key.hovered = false;
    tryCompare(key, "faceY", 0, 1000);
    key.latched = true;
    compare(key.sink, 2);
  }
  }
