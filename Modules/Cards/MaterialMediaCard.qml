import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import qs.Commons
import qs.Services.Media
import qs.Widgets
import qs.Widgets.AudioSpectrum

Rectangle {
  id: root
  property bool expanded: false
  property bool showAlbumArt: true
  property bool showVisualizer: Settings.data.audio.visualizerType !== "none" && Settings.data.audio.visualizerType !== ""
  property string spectrumId: "material-media-card"
  readonly property bool hasPlayer: !!MediaService.currentPlayer
  readonly property bool needsSpectrum: expanded && hasPlayer && showVisualizer
  implicitWidth: Math.round(416 * Style.uiScaleRatio)
  implicitHeight: Math.round((expanded ? 380 : 220) * Style.uiScaleRatio)
  radius: Style.radiusL
  color: Qt.tint(Color.mSurfaceVariant, Qt.alpha(Color.mPrimary, 0.08))
  clip: true

  onNeedsSpectrumChanged: {
    if (needsSpectrum)
      SpectrumService.registerComponent(spectrumId);
    else
      SpectrumService.unregisterComponent(spectrumId);
  }
  Component.onCompleted: {
    if (needsSpectrum)
      SpectrumService.registerComponent(spectrumId);
  }
  Component.onDestruction: {
    SpectrumService.unregisterComponent(spectrumId);
    if (seek.pressed)
      MediaService.isSeeking = false;
  }

  // Artwork gives the card its atmosphere without competing with metadata.
  Item {
    anchors.fill: parent
    visible: root.showAlbumArt && MediaService.trackArtUrl !== ""
    layer.enabled: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: ShaderEffectSource {
        sourceItem: Rectangle {
          width: root.width
          height: root.height
          radius: root.radius
        }
      }
    }
    Image {
      anchors.fill: parent
      source: MediaService.trackArtUrl
      fillMode: Image.PreserveAspectCrop
      sourceSize: Qt.size(512, 512)
      opacity: 0.65
    }
    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop {
          position: 0
          color: Qt.alpha(Color.mSurface, 0.35)
        }
        GradientStop {
          position: 1
          color: Qt.alpha(Color.mSurface, 0.85)
        }
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Math.round(18 * Style.uiScaleRatio)
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      NIcon {
        icon: "disc"
        color: Color.mPrimary
        pointSize: Style.fontSizeS
      }
      NText {
        Layout.fillWidth: true
        text: MediaService.currentPlayer?.identity || I18n.tr("control-center.media-title")
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        elide: Text.ElideRight
      }
      Rectangle {
        Layout.preferredWidth: Math.round(136 * Style.uiScaleRatio)
        Layout.preferredHeight: Math.round(26 * Style.uiScaleRatio)
        radius: height / 2
        color: Qt.tint(Color.mSurfaceVariant, Qt.alpha(Color.mPrimary, 0.16))
        RowLayout {
          id: outputLabel
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: Style.marginXS
          NIcon {
            icon: "headphones"
            pointSize: Style.fontSizeXS
            color: Color.mOnSurface
          }
          NText {
            Layout.fillWidth: true
            text: AudioService.sink?.description || I18n.tr("control-center.audio-output")
            elide: Text.ElideRight
            pointSize: Style.fontSizeXS
          }
        }
      }
      NIconButton {
        visible: MediaService.getAvailablePlayers().length > 1
        icon: "caret-down"
        baseSize: Style.baseWidgetSize * 0.8
        tooltipText: I18n.tr("control-center.choose-player")
        onClicked: {
          playerMenu.model = MediaService.getAvailablePlayers().map((player, index) => ({
            label: player.identity,
            action: String(index),
            icon: "disc"
          }));
          playerMenu.openAtItem(this, 0, height);
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Style.marginL
      ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: Style.marginXS
        NText {
          Layout.fillWidth: true
          text: root.hasPlayer ? MediaService.trackTitle : I18n.tr("bar.media-mini.no-active-player")
          pointSize: root.expanded ? Style.fontSizeXXL : Style.fontSizeL
          font.weight: Style.fontWeightMedium
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }
        NText {
          Layout.fillWidth: true
          text: MediaService.trackArtist
          visible: text !== ""
          pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
          elide: Text.ElideRight
        }
        NText {
          Layout.fillWidth: true
          visible: root.expanded && text !== ""
          text: MediaService.trackAlbum
          pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
          elide: Text.ElideRight
        }
      }
      NImageRounded {
        visible: root.expanded && root.showAlbumArt && MediaService.trackArtUrl !== ""
        Layout.preferredWidth: Math.round((root.expanded ? 128 : 72) * Style.uiScaleRatio)
        Layout.preferredHeight: Layout.preferredWidth
        radius: Style.radiusS
        imagePath: MediaService.trackArtUrl
        fallbackIcon: "disc"
      }
      Rectangle {
        Layout.preferredWidth: Math.round(64 * Style.uiScaleRatio)
        Layout.preferredHeight: Math.round(52 * Style.uiScaleRatio)
        radius: Math.min(Style.iRadiusM, height / 2)
        color: Color.mPrimary
        opacity: MediaService.canPlay || MediaService.canPause ? 1 : 0.45
        NMaterialStateLayer {
          hovered: playPointer.containsMouse
          pressed: playPointer.pressed
          tint: Color.mOnPrimary
        }
        NIcon {
          anchors.centerIn: parent
          icon: MediaService.isPlaying ? "media-pause" : "media-play"
          pointSize: Style.fontSizeXXL
          color: Color.mOnPrimary
        }
        Accessible.role: Accessible.Button
        Accessible.name: I18n.tr(MediaService.isPlaying ? "common.pause" : "common.play")
        Accessible.onPressAction: MediaService.playPause()
        MouseArea {
          id: playPointer
          anchors.fill: parent
          enabled: MediaService.canPlay || MediaService.canPause
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: MediaService.playPause()
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: Math.round(28 * Style.uiScaleRatio)
      visible: root.hasPlayer && MediaService.trackLength > 0
      NMaterialMediaSlider {
        id: seek
        anchors.fill: parent
        from: 0
        to: 1
        stepSize: 0
        playing: MediaService.isPlaying
        motionEnabled: !Settings.data.general.animationDisabled
        unit: Style.uiScaleRatio
        accent: Color.mPrimary
        trackColor: Color.mOutline
        Accessible.name: I18n.tr("control-center.seek")
        enabled: root.hasPlayer && MediaService.trackLength > 0 && MediaService.canSeek
        property real pendingRatio: 0
        onMoved: {
          pendingRatio = value;
          if (pressed)
            seekTimer.restart();
          else
            MediaService.seekByRatio(value);
        }
        onPressedChanged: {
          MediaService.isSeeking = pressed;
          if (!pressed) {
            seekTimer.stop();
            MediaService.seekByRatio(value);
          }
        }
        Binding {
          target: seek
          property: "value"
          value: ControlCenterLayout.progress(MediaService.currentPosition, MediaService.trackLength)
          when: !seek.pressed
        }
      }
      Timer {
        id: seekTimer
        interval: 75
        onTriggered: MediaService.seekByRatio(seek.pendingRatio)
      }
    }

    NWaveSpectrum {
      Layout.fillWidth: true
      Layout.preferredHeight: Math.round(18 * Style.uiScaleRatio)
      visible: root.expanded && root.needsSpectrum && MediaService.isPlaying
      values: SpectrumService.values
      fillColor: Color.mPrimary
      opacity: 0.35
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS
      NText {
        Layout.fillWidth: true
        text: root.hasPlayer ? MediaService.positionString + " / " + MediaService.lengthString : ""
        pointSize: Style.fontSizeXS
        color: Color.mOnSurfaceVariant
      }
      NIconButton {
        icon: "media-prev"
        enabled: MediaService.canGoPrevious
        tooltipText: I18n.tr("common.previous")
        onClicked: MediaService.previous()
      }

      NIconButton {
        icon: "media-next"
        enabled: MediaService.canGoNext
        tooltipText: I18n.tr("common.next")
        onClicked: MediaService.next()
      }
    }
  }
  NContextMenu {
    id: playerMenu
    width: Math.round(220 * Style.uiScaleRatio)
    onTriggered: action => MediaService.switchToPlayer(parseInt(action))
  }
}
