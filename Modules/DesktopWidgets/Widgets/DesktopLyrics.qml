import QtQuick
import Quickshell
import "../../../Helpers/Lyrics.js" as Lyrics
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Services.Media
import qs.Services.UI
import qs.Widgets

// Synced lyrics on the desktop: the line being sung filling as it is sung, the line
// before fading above and the next one waiting below. This file keeps the lyrics clock
// and the stack; the style's "lyrics" view draws them, reading everything from
// `lyrics` (this item). After SekaiPop's lyrics widget (github.com/Blapples/SekaiPop,
// GPL-3.0). Lyrics come from LyricsService.
DraggableDesktopWidget {
  id: root
  horizontalResizable: true
  defaultY: 420

  readonly property var widgetMetadata: DesktopWidgetRegistry.widgetMetadata["Lyrics"]
  readonly property bool showTrack: (widgetData && widgetData.showTrack !== undefined) ? widgetData.showTrack : (widgetMetadata?.showTrack ?? false)
  readonly property string colorName: (widgetData && widgetData.colorName !== undefined) ? widgetData.colorName : (widgetMetadata?.colorName ?? "primary")
  readonly property int baseWidth: (widgetData && widgetData.width !== undefined) ? widgetData.width : (widgetMetadata?.width ?? 760)

  readonly property bool hasLyrics: LyricsService.lines.length > 0
  readonly property bool instrumental: LyricsService.state === "instrumental"
  readonly property bool demo: editing && !hasLyrics && !instrumental
  readonly property bool playing: MediaService.isPlaying || demo
  readonly property bool wanted: MediaService.currentPlayer !== null

  visible: hasLyrics || instrumental || DesktopWidgetRegistry.editMode
  opacity: MediaService.isPlaying || editing ? 1 : 0.62
  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationNormal
    }
  }

  readonly property string userId: "desktop:lyrics:" + (screen ? screen.name : "unknown") + ":" + widgetIndex
  onWantedChanged: wanted ? LyricsService.registerUser(userId) : LyricsService.unregisterUser(userId)
  Component.onCompleted: {
    if (wanted)
      LyricsService.registerUser(userId);
  }
  Component.onDestruction: LyricsService.unregisterUser(userId)

  implicitWidth: Math.round(baseWidth * widgetScale)
  implicitHeight: Math.round(250 * widgetScale)

  // ===== The lyrics clock =====
  // MPRIS positions arrive about once a second; between them the clock runs on.

  property real basePosition: MediaService.currentPosition
  property real baseAt: Date.now()
  property real now: Date.now()
  // Light a word a touch early, the way it reads as on time
  readonly property real lead: 0.12
  readonly property real t: (MediaService.isPlaying ? basePosition + Math.max(0, now - baseAt) / 1000 : basePosition) + lead

  Connections {
    target: MediaService
    function onCurrentPositionChanged() {
      // The player's own reading is better while it comes (LyricsService); a seek
      // still lands here at once
      if (LyricsService.playerBus !== "" && MediaService.isPlaying && Math.abs(MediaService.currentPosition - root.t + root.lead) < 1.5 + root.drift)
        return;
      root.basePosition = MediaService.currentPosition;
      root.baseAt = Date.now();
      root.now = root.baseAt;
    }
    function onIsPlayingChanged() {
      root.basePosition = MediaService.currentPosition;
      root.baseAt = Date.now();
    }
  }

  // How far Quickshell's running position was off at the last reading, so a stall
  // that pushed it ahead isn't mistaken for a seek
  property real drift: 0

  Connections {
    target: LyricsService
    function onPositionSampled(position, at) {
      root.drift = Math.abs(MediaService.currentPosition - position);
      root.basePosition = position;
      root.baseAt = at;
      root.now = Date.now();
    }
  }

  FrameAnimation {
    running: root.visible && root.hasLyrics && MediaService.isPlaying
    onTriggered: root.now = Date.now()
  }

  // ===== The stack =====

  readonly property var demoLines: [
    {
      "start": -100,
      "end": 1e9,
      "text": I18n.tr("panels.desktop-widgets.lyrics-demo"),
      "words": []
    }
  ]
  readonly property var lines: demo ? demoLines : LyricsService.lines
  readonly property real cursor: Lyrics.cursor(lines, t, 0.45)
  readonly property int curIndex: Lyrics.lineIndexAt(lines, t)
  readonly property var waiting: Lyrics.waiting(lines, t, 6)
  readonly property string trackTag: Lyrics.trackTag(MediaService.trackTitle, MediaService.trackArtist)
  readonly property string trackLine: Lyrics.trackLine(MediaService.trackTitle, MediaService.trackArtist)

  readonly property int pixelSize: Math.round(46 * widgetScale)
  readonly property real stageY: height * (showTrack ? 0.42 : 0.5)
  readonly property color litColor: ShellColors.resolveColorKey(colorName)
  // The second colour: the marker, the ad libs
  readonly property color accentColor: colorName === "secondary" ? ShellColors.mTertiary : ShellColors.mSecondary
  readonly property string family: Style.fontDefault

  NStyleView {
    anchors.fill: parent
    surface: "lyrics"
    viewProperties: ({
                       "lyrics": root
                     })
  }
}
