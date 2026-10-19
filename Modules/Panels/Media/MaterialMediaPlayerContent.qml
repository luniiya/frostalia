import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import "../../../Helpers/MediaPopup.js" as MediaPopup
import qs.Commons
import qs.Services.Media
import qs.Widgets
import qs.Widgets.AudioSpectrum

// Compact bar popup modelled on end-4's media controls: art left, metadata and wavy seek bar right.
Item {
  id: root
  required property var panel

  readonly property real unit: Style.uiScaleRatio
  readonly property real padding: Math.round(12 * unit)
  readonly property bool hasPlayer: !!MediaService.currentPlayer
  readonly property bool hasArt: panel.showAlbumArt && MediaService.trackArtUrl !== ""
  readonly property string visualizer: MediaPopup.backgroundVisualizer(Settings.data.audio.visualizerType)
  readonly property bool needsSpectrum: visualizer !== "" && panel.isPanelOpen && hasPlayer
  readonly property int artSize: MediaPopup.artSize(width, height, padding, 160 * unit)

  implicitWidth: Math.round(400 * unit)
  implicitHeight: Math.round(132 * unit)

  Component.onDestruction: {
    if (seek.pressed)
      MediaService.isSeeking = false;
  }

  // Blurred artwork and a faint spectrum hill sit behind the controls.
  Item {
    anchors.fill: parent
    layer.enabled: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: ShaderEffectSource {
        sourceItem: Rectangle {
          width: root.width
          height: root.height
          radius: Style.radiusL
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      color: Qt.tint(Color.mSurfaceVariant, Qt.alpha(Color.mPrimary, 0.08))
    }
    Image {
      anchors.fill: parent
      visible: root.hasArt
      source: root.hasArt ? MediaService.trackArtUrl : ""
      fillMode: Image.PreserveAspectCrop
      sourceSize: Qt.size(256, 256)
      layer.enabled: true
      layer.effect: MultiEffect {
        blurEnabled: true
        blur: 1
        blurMax: 64
        saturation: 0.2
      }
    }
    Rectangle {
      anchors.fill: parent
      visible: root.hasArt
      color: Qt.alpha(Color.mSurface, 0.7)
    }
    // Bars rise from the bottom edge behind the controls.
    NLinearSpectrum {
      width: parent.width
      height: parent.height * 0.8
      anchors.bottom: parent.bottom
      visible: root.visualizer === "bars" && root.needsSpectrum && MediaService.isPlaying
      values: SpectrumService.values
      fillColor: Qt.alpha(Color.mPrimary, 0.5)
      mirrored: Settings.data.audio.spectrumMirrored
    }
    // The shader fills center ± amplitude, so a double-height item centered on the bottom edge reads as a hill.
    NWaveSpectrum {
      width: parent.width
      height: parent.height * 1.6
      anchors.verticalCenter: parent.bottom
      visible: root.visualizer === "wave" && root.needsSpectrum && MediaService.isPlaying
      values: SpectrumService.values
      fillColor: Qt.alpha(Color.mPrimary, 0.5)
      mirrored: true
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: root.padding

    NImageRounded {
      visible: root.panel.showAlbumArt && root.artSize > 0
      Layout.preferredWidth: root.artSize
      Layout.preferredHeight: root.artSize
      Layout.alignment: Qt.AlignVCenter
      radius: Style.radiusM
      imagePath: MediaService.trackArtUrl
      fallbackIcon: "disc"
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumWidth: 0
      spacing: 0

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS
        NText {
          Layout.fillWidth: true
          text: root.hasPlayer ? MediaService.trackTitle : I18n.tr("bar.media-mini.no-active-player")
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightMedium
          elide: Text.ElideRight
        }
        NIconButton {
          visible: MediaService.getAvailablePlayers().length > 1
          icon: "caret-down"
          baseSize: Style.baseWidgetSize * 0.7
          colorBg: "transparent"
          colorFg: Color.mOnSurfaceVariant
          tooltipText: I18n.tr("control-center.choose-player")
          onClicked: {
            playerMenu.model = MediaService.getAvailablePlayers().map((player, index) => ({
              label: player.identity,
              action: String(index),
              icon: index === MediaService.selectedPlayerIndex ? "check" : "disc"
            }));
            playerMenu.openAtItem(this, 0, height);
          }
        }
      }
      NText {
        Layout.fillWidth: true
        text: MediaService.trackArtist
        visible: text !== ""
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        elide: Text.ElideRight
      }

      Item {
        Layout.fillHeight: true
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS
        NText {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignBottom
          text: MediaPopup.timeLabel(root.hasPlayer, MediaService.positionString, MediaService.trackLength > 0 ? MediaService.lengthString : "")
          pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
        }
        Rectangle {
          id: playButton
          readonly property int size: Math.round(44 * root.unit)
          Layout.preferredWidth: size
          Layout.preferredHeight: size
          radius: MediaPopup.playButtonRadius(size, MediaService.isPlaying)
          color: Color.mPrimary
          opacity: MediaService.canPlay || MediaService.canPause ? 1 : 0.45
          Behavior on radius {
            NumberAnimation {
              duration: Style.animationFast
              easing.type: Easing.OutCubic
            }
          }
          NMaterialStateLayer {
            hovered: playPointer.containsMouse
            pressed: playPointer.pressed
            tint: Color.mOnPrimary
          }
          NIcon {
            anchors.centerIn: parent
            icon: MediaService.isPlaying ? "media-pause" : "media-play"
            pointSize: Style.fontSizeXL
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

      RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginXS
        spacing: Style.marginXS
        NIconButton {
          icon: "media-prev"
          baseSize: Style.baseWidgetSize * 0.7
          colorBg: "transparent"
          colorFg: Color.mOnSurface
          enabled: MediaService.canGoPrevious
          tooltipText: I18n.tr("common.previous")
          onClicked: MediaService.previous()
        }
        NMaterialMediaSlider {
          id: seek
          Layout.fillWidth: true
          Layout.preferredHeight: Math.round(20 * root.unit)
          from: 0
          to: 1
          stepSize: 0
          playing: MediaService.isPlaying
          motionEnabled: !Settings.data.general.animationDisabled
          unit: root.unit
          accent: Color.mPrimary
          trackColor: Qt.alpha(Color.mOnSurface, 0.25)
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
        NIconButton {
          icon: "media-next"
          baseSize: Style.baseWidgetSize * 0.7
          colorBg: "transparent"
          colorFg: Color.mOnSurface
          enabled: MediaService.canGoNext
          tooltipText: I18n.tr("common.next")
          onClicked: MediaService.next()
        }
      }
    }
  }

  Timer {
    id: seekTimer
    interval: 75
    onTriggered: MediaService.seekByRatio(seek.pendingRatio)
  }

  NContextMenu {
    id: playerMenu
    width: Math.round(220 * root.unit)
    onTriggered: action => MediaService.switchToPlayer(parseInt(action))
  }
}
