import QtQuick
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Phone media player: art, title, seek bar, transport and volume. The compact
// form is used on the home pages.
ColumnLayout {
  id: root
  property bool expanded: false
  readonly property var media: KdeConnectService.activeDevice?.media || null
  readonly property bool hasMedia: !!media && media.title !== ""

  // The phone reports the position on changes only; advance it locally.
  property real basePosition: media ? media.position : 0
  property real baseTime: Date.now()
  property real now: Date.now()
  readonly property real position: media && media.playing ? Math.min(media.length, basePosition + now - baseTime) : basePosition
  onMediaChanged: {
    basePosition = media ? media.position : 0;
    baseTime = Date.now();
    now = baseTime;
  }
  Timer {
    interval: 1000
    repeat: true
    running: root.visible && !!root.media && root.media.playing
    onTriggered: root.now = Date.now()
  }

  spacing: Style.marginM

  KdeConnectEmptyState {
    Layout.fillWidth: true
    Layout.fillHeight: root.expanded
    visible: !root.hasMedia
    icon: "music-off"
    title: I18n.tr("kdeconnect.media.nothing-playing")
  }

  NImageRounded {
    visible: root.hasMedia && root.expanded
    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: Math.round(220 * Style.uiScaleRatio)
    Layout.preferredHeight: Layout.preferredWidth
    radius: Style.radiusL
    imagePath: root.media?.artUrl || ""
    fallbackIcon: "music"
    fallbackIconSize: Style.fontSizeXXXL * 2
  }

  RowLayout {
    visible: root.hasMedia
    Layout.fillWidth: true
    spacing: Style.marginM
    NImageRounded {
      visible: !root.expanded
      Layout.preferredWidth: Math.round(52 * Style.uiScaleRatio)
      Layout.preferredHeight: Layout.preferredWidth
      radius: Style.radiusS
      imagePath: root.media?.artUrl || ""
      fallbackIcon: "music"
    }
    ColumnLayout {
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: 0
      NText {
        Layout.fillWidth: true
        text: root.media?.title || ""
        pointSize: root.expanded ? Style.fontSizeXL : Style.fontSizeM
        font.weight: Style.fontWeightSemiBold
        horizontalAlignment: root.expanded ? Text.AlignHCenter : Text.AlignLeft
        elide: Text.ElideRight
      }
      NText {
        Layout.fillWidth: true
        visible: text !== ""
        text: [root.media?.artist, root.expanded ? root.media?.album : ""].filter(s => !!s).join(" · ")
        pointSize: Style.fontSizeS
        color: ShellColors.mOnSurfaceVariant
        horizontalAlignment: root.expanded ? Text.AlignHCenter : Text.AlignLeft
        elide: Text.ElideRight
      }
    }
    RowLayout {
      visible: !root.expanded
      spacing: 0
      NIconButton {
        icon: "player-skip-back"
        baseSize: Style.baseWidgetSize * 0.85
        onClicked: KdeConnectService.mediaAction("Previous")
      }
      NIconButton {
        icon: root.media?.playing ? "player-pause-filled" : "player-play-filled"
        baseSize: Style.baseWidgetSize * 0.95
        colorBg: ShellColors.mPrimary
        colorFg: ShellColors.mOnPrimary
        onClicked: KdeConnectService.mediaAction("PlayPause")
      }
      NIconButton {
        icon: "player-skip-forward"
        baseSize: Style.baseWidgetSize * 0.85
        onClicked: KdeConnectService.mediaAction("Next")
      }
    }
  }

  ColumnLayout {
    visible: root.hasMedia && root.expanded
    Layout.fillWidth: true
    spacing: 0
    NSlider {
      Layout.fillWidth: true
      from: 0
      to: Math.max(1, root.media?.length || 1)
      value: root.position
      enabled: !!root.media?.canSeek
      onMoved: KdeConnectService.mediaSetPosition(value)
    }
    RowLayout {
      Layout.fillWidth: true
      NText {
        text: KdeConnect.formatDuration(root.position)
        pointSize: Style.fontSizeXS
        color: ShellColors.mOnSurfaceVariant
      }
      Item {
        Layout.fillWidth: true
      }
      NText {
        text: KdeConnect.formatDuration(root.media?.length || 0)
        pointSize: Style.fontSizeXS
        color: ShellColors.mOnSurfaceVariant
      }
    }
  }

  RowLayout {
    visible: root.hasMedia && root.expanded
    Layout.alignment: Qt.AlignHCenter
    spacing: Style.marginL
    NIconButton {
      icon: "player-skip-back"
      baseSize: Style.baseWidgetSize * 1.2
      onClicked: KdeConnectService.mediaAction("Previous")
    }
    NIconButton {
      icon: root.media?.playing ? "player-pause-filled" : "player-play-filled"
      baseSize: Style.baseWidgetSize * 1.6
      colorBg: ShellColors.mPrimary
      colorFg: ShellColors.mOnPrimary
      onClicked: KdeConnectService.mediaAction("PlayPause")
    }
    NIconButton {
      icon: "player-skip-forward"
      baseSize: Style.baseWidgetSize * 1.2
      onClicked: KdeConnectService.mediaAction("Next")
    }
  }

  RowLayout {
    visible: root.hasMedia && root.expanded
    Layout.fillWidth: true
    spacing: Style.marginS
    NIcon {
      icon: "volume"
      color: ShellColors.mOnSurfaceVariant
    }
    NSlider {
      Layout.fillWidth: true
      from: 0
      to: 100
      value: root.media?.volume || 0
      onMoved: KdeConnectService.mediaSetVolume(value)
    }
  }

  // Player picker when several apps play on the phone.
  NButton {
    visible: root.expanded && (root.media?.players || []).length > 1
    Layout.alignment: Qt.AlignHCenter
    text: root.media?.player || ""
    icon: "chevron-down"
    outlined: true
    onClicked: {
      playerMenu.model = root.media.players.map(p => ({
        label: p,
        action: p,
        icon: p === root.media.player ? "check" : "disc"
      }));
      playerMenu.openAtItem(this, 0, height);
    }
  }

  Item {
    visible: root.expanded && root.hasMedia
    Layout.fillHeight: true
  }

  NContextMenu {
    id: playerMenu
    width: Math.round(220 * Style.uiScaleRatio)
    onTriggered: action => KdeConnectService.mediaSetPlayer(action)
  }
}
