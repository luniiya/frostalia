import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.Media
import qs.Services.UI
import qs.Widgets
import qs.Widgets.AudioSpectrum

Item {
  id: playerContent
  required property var panel
  implicitWidth: Math.round((panel.isSideBySide ? 480 : 360) * Style.uiScaleRatio)
  implicitHeight: contentPreferredHeight
  readonly property bool needsSpectrum: panel.showVisualizer && panel.visualizerType !== "" && panel.visualizerType !== "none" && panel.isPanelOpen
  anchors.fill: parent

  property real contentPreferredHeight: mainLayout.implicitHeight + Style.margin2L

  property Component visualizerSource: {
    switch (panel.visualizerType) {
    case "linear":
      return linearComponent;
    case "mirrored":
      return mirroredComponent;
    case "wave":
      return waveComponent;
    default:
      return null;
    }
  }

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    NBox {
      Layout.fillWidth: true
      Layout.preferredHeight: headerRow.implicitHeight + Style.margin2M

      RowLayout {
        id: headerRow
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        NIcon {
          icon: "music"
          pointSize: Style.fontSizeL
          color: ShellColors.mPrimary
        }

        NText {
          text: I18n.tr("common.media-player")
          font.weight: Style.fontWeightBold
          pointSize: Style.fontSizeL
          color: ShellColors.mOnSurface
          Layout.fillWidth: true
        }

        Rectangle {
          radius: Style.radiusS
          color: playerSelectorMouse.containsMouse ? ShellColors.mPrimary : "transparent"
          implicitWidth: playerRow.implicitWidth + Style.marginM
          implicitHeight: Style.baseWidgetSize * 0.8
          visible: MediaService.getAvailablePlayers().length > 1

          RowLayout {
            id: playerRow
            anchors.centerIn: parent
            spacing: Style.marginXS

            NText {
              text: MediaService.currentPlayer ? MediaService.currentPlayer.identity : "Select Player"
              pointSize: Style.fontSizeXS
              color: playerSelectorMouse.containsMouse ? ShellColors.mOnPrimary : ShellColors.mOnSurfaceVariant
            }
            NIcon {
              icon: "chevron-down"
              pointSize: Style.fontSizeXS
              color: playerSelectorMouse.containsMouse ? ShellColors.mOnPrimary : ShellColors.mOnSurfaceVariant
            }
          }

          MouseArea {
            id: playerSelectorMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: playerContextMenu.open()
          }

          Popup {
            id: playerContextMenu
            x: 0
            y: parent.height
            width: 160
            padding: Style.marginS

            background: Rectangle {
              color: ShellColors.mSurfaceVariant
              border.color: ShellColors.mOutline
              border.width: Style.borderS
              radius: Style.iRadiusM
            }

            contentItem: ColumnLayout {
              spacing: 0
              Repeater {
                model: MediaService.getAvailablePlayers()
                delegate: Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 30
                  color: "transparent"

                  Rectangle {
                    anchors.fill: parent
                    color: itemMouse.containsMouse ? ShellColors.mPrimary : "transparent"
                    radius: Style.iRadiusS
                  }

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS

                    NIcon {
                      visible: MediaService.currentPlayer && MediaService.currentPlayer.identity === modelData.identity
                      icon: "check"
                      color: itemMouse.containsMouse ? ShellColors.mOnPrimary : ShellColors.mPrimary
                      pointSize: Style.fontSizeS
                    }

                    NText {
                      text: modelData.identity
                      pointSize: Style.fontSizeS
                      color: itemMouse.containsMouse ? ShellColors.mOnPrimary : ShellColors.mOnSurface
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                  }

                  MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      MediaService.currentPlayer = modelData;
                      playerContextMenu.close();
                    }
                  }
                }
              }
            }
          }
        }

        NIconButton {
          icon: "close"
          tooltipText: I18n.tr("common.close")
          baseSize: Style.baseWidgetSize * 0.8
          onClicked: panel.close()
        }
      }
    }

    NBox {
      Layout.fillWidth: true
      Layout.preferredHeight: mediaContentGrid.implicitHeight + Style.margin2M

      // Visualizer background for content area
      Loader {
        anchors.fill: parent
        z: 0
        active: !!(panel.needsSpectrum && !panel.showAlbumArt)
        sourceComponent: visualizerSource
      }

      GridLayout {
        id: mediaContentGrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: panel.compactMode ? Style.marginL : Style.marginM
        anchors.rightMargin: panel.compactMode ? Style.marginL : Style.marginM
        anchors.topMargin: Style.marginM
        anchors.bottomMargin: Style.marginM
        columns: panel.isSideBySide ? 2 : 1
        columnSpacing: Style.marginL
        rowSpacing: panel.compactMode ? Style.marginL : Style.marginM

        // Album Art (Vertical in normal, Horizontal in compact)
        Item {
          id: albumArtItem
          readonly property real compactArtSize: Math.round(110 * Style.uiScaleRatio)
          readonly property bool artSizeKnown: artSizeProbe.status === Image.Ready && artSizeProbe.sourceSize.width > 0 && artSizeProbe.sourceSize.height > 0
          readonly property real artAspectRatio: artSizeKnown ? artSizeProbe.sourceSize.width / artSizeProbe.sourceSize.height : 1
          // Non-compact: height from width÷aspect so grid implicit height does not depend on panel height (no layout loop).
          readonly property real artBoxW: panel.compactMode ? compactArtSize : Math.max(parent.width, 1)
          readonly property real artBoxH: panel.compactMode ? compactArtSize : (artBoxW / Math.max(artAspectRatio, 0.001))
          readonly property real fitArtW: artBoxW / artBoxH > artAspectRatio ? artBoxH * artAspectRatio : artBoxW
          readonly property real fitArtH: artBoxW / artBoxH > artAspectRatio ? artBoxH : artBoxW / artAspectRatio

          Layout.preferredWidth: fitArtW
          Layout.preferredHeight: fitArtH
          Layout.minimumWidth: fitArtW
          Layout.maximumWidth: fitArtW
          Layout.minimumHeight: fitArtH
          Layout.maximumHeight: fitArtH
          Layout.fillWidth: false
          Layout.fillHeight: false
          Layout.alignment: Qt.AlignHCenter
          visible: panel.showAlbumArt

          Image {
            id: artSizeProbe
            visible: false
            asynchronous: true
            source: MediaService.trackArtUrl
          }

          NImageRounded {
            anchors.fill: parent
            radius: panel.compactMode ? Style.radiusM : Style.radiusL
            imagePath: MediaService.trackArtUrl
            imageFillMode: Image.PreserveAspectCrop
            fallbackIcon: "disc"
            fallbackIconSize: panel.compactMode ? Style.fontSizeXXXL * 3 : Style.fontSizeXXXL * 6
            borderWidth: 0
          }

          Loader {
            anchors.fill: parent
            anchors.margins: Style.marginS
            z: 2
            active: !!(panel.needsSpectrum && panel.showAlbumArt)
            sourceComponent: visualizerSource
          }
        }

        ColumnLayout {
          id: controlsLayout
          Layout.preferredWidth: panel.compactMode ? -1 : albumArtItem.width
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignHCenter
          Layout.fillHeight: panel.compactMode
          spacing: panel.compactMode ? Style.marginXS : Style.marginS

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            NScrollText {
              Layout.fillWidth: true
              maxWidth: parent.width
              text: {
                if (panel.showArtistFirst) {
                  return MediaService.trackArtist || (MediaService.trackAlbum || "Unknown Artist");
                } else {
                  return MediaService.trackTitle || "No Media";
                }
              }

              scrollMode: {
                if (panel.scrollingMode === "always")
                  return NScrollText.ScrollMode.Always;
                if (panel.scrollingMode === "hover")
                  return NScrollText.ScrollMode.Hover;
                return NScrollText.ScrollMode.Never;
              }
              fadeExtent: 0.01
              fadeCornerRadius: Style.radiusM

              delegate: NText {
                pointSize: panel.compactMode ? Style.fontSizeL : Style.fontSizeXL
                font.weight: Style.fontWeightBold
                color: ShellColors.mOnSurface
                horizontalAlignment: panel.isSideBySide ? Text.AlignLeft : Text.AlignHCenter
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
              }
            }

            NScrollText {
              Layout.fillWidth: true
              maxWidth: parent.width
              text: {
                if (panel.showArtistFirst) {
                  return MediaService.trackTitle || "No Media";
                } else {
                  return MediaService.trackArtist || (MediaService.trackAlbum || "Unknown Artist");
                }
              }

              scrollMode: {
                if (panel.scrollingMode === "always")
                  return NScrollText.ScrollMode.Always;
                if (panel.scrollingMode === "hover")
                  return NScrollText.ScrollMode.Hover;
                return NScrollText.ScrollMode.Never;
              }
              fadeExtent: 0.01
              fadeCornerRadius: Style.radiusM

              delegate: NText {
                pointSize: panel.compactMode ? Style.fontSizeS : Style.fontSizeM
                color: ShellColors.mOnSurfaceVariant
                horizontalAlignment: panel.isSideBySide ? Text.AlignLeft : Text.AlignHCenter
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
              }
            }
          }

          Item {
            id: progressWrapper
            visible: (MediaService.currentPlayer && MediaService.trackLength > 0)
            Layout.fillWidth: true
            Layout.preferredHeight: progressColumn.implicitHeight

            property real localSeekRatio: -1
            property real lastSentSeekRatio: -1
            property real seekEpsilon: 0.01
            property real progressRatio: {
              if (!MediaService.currentPlayer || MediaService.trackLength <= 0)
                return 0;
              const r = MediaService.currentPosition / MediaService.trackLength;
              if (isNaN(r) || !isFinite(r))
                return 0;
              return Math.max(0, Math.min(1, r));
            }

            Timer {
              id: seekDebounce
              interval: 75
              repeat: false
              onTriggered: {
                if (MediaService.isSeeking && progressWrapper.localSeekRatio >= 0) {
                  const next = Math.max(0, Math.min(1, progressWrapper.localSeekRatio));
                  if (progressWrapper.lastSentSeekRatio < 0 || Math.abs(next - progressWrapper.lastSentSeekRatio) >= progressWrapper.seekEpsilon) {
                    MediaService.seekByRatio(next);
                    progressWrapper.lastSentSeekRatio = next;
                  }
                }
              }
            }

            ColumnLayout {
              id: progressColumn
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              spacing: 2

              Item {
                Layout.fillWidth: true
                Layout.preferredHeight: panel.compactMode ? (Style.baseWidgetSize * 0.4) : (Style.baseWidgetSize * 0.5)

                NSlider {
                  id: progressSlider
                  anchors.fill: parent
                  from: 0
                  to: 1
                  stepSize: 0
                  snapAlways: false
                  enabled: MediaService.trackLength > 0 && MediaService.canSeek
                  heightRatio: 0.4

                  value: (!MediaService.isSeeking) ? progressWrapper.progressRatio : (progressWrapper.localSeekRatio >= 0 ? progressWrapper.localSeekRatio : 0)

                  onMoved: {
                    progressWrapper.localSeekRatio = value;
                    seekDebounce.restart();
                  }
                  onPressedChanged: {
                    if (pressed) {
                      MediaService.isSeeking = true;
                      progressWrapper.localSeekRatio = value;
                      MediaService.seekByRatio(value);
                      progressWrapper.lastSentSeekRatio = value;
                    } else {
                      seekDebounce.stop();
                      MediaService.seekByRatio(value);
                      MediaService.isSeeking = false;
                      progressWrapper.localSeekRatio = -1;
                      progressWrapper.lastSentSeekRatio = -1;
                    }
                  }
                }
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 0

                NText {
                  text: MediaService.positionString || "0:00"
                  pointSize: Style.fontSizeXS
                  color: ShellColors.mOnSurfaceVariant
                  visible: progressWrapper.visible
                }

                Item {
                  Layout.fillWidth: true
                  Layout.minimumWidth: 0
                }

                NText {
                  text: MediaService.lengthString || "0:00"
                  pointSize: Style.fontSizeXS
                  color: ShellColors.mOnSurfaceVariant
                  horizontalAlignment: Text.AlignRight
                  visible: progressWrapper.visible
                }
              }
            }
          }

          Item {
            Layout.preferredHeight: panel.isSideBySide ? Style.marginM : Style.marginS
          }

          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: panel.isSideBySide ? Style.marginL : Style.marginXL

            NIconButton {
              icon: "media-prev"
              baseSize: panel.compactMode ? (Style.baseWidgetSize * 0.9) : (Style.baseWidgetSize * 1.2)
              onClicked: MediaService.previous()
            }

            Rectangle {
              implicitWidth: panel.compactMode ? (Style.baseWidgetSize * 1.3) : (Style.baseWidgetSize * 1.8)
              implicitHeight: panel.compactMode ? (Style.baseWidgetSize * 1.3) : (Style.baseWidgetSize * 1.8)
              radius: panel.compactMode ? Style.iRadiusM : Style.iRadiusL
              color: ShellColors.mPrimary

              NIcon {
                anchors.centerIn: parent
                icon: MediaService.isPlaying ? "media-pause" : "media-play"
                pointSize: panel.compactMode ? Style.fontSizeL : Style.fontSizeXXL
                color: ShellColors.mOnPrimary
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: parent.color = ShellColors.mPrimary
                onClicked: MediaService.playPause()
              }
            }

            NIconButton {
              icon: "media-next"
              baseSize: panel.compactMode ? (Style.baseWidgetSize * 0.9) : (Style.baseWidgetSize * 1.2)
              onClicked: MediaService.next()
            }
          }
        }
      }
    }
  }

  // Visualizer Components
  Component {
    id: linearComponent
    NLinearSpectrum {
      width: parent.width - Style.marginS
      height: 20
      values: SpectrumService.values
      fillColor: ShellColors.mPrimary
      opacity: 0.4
      barPosition: Settings.getBarPositionForScreen(panel.screen?.name)
      mirrored: Settings.data.audio.spectrumMirrored
    }
  }

  Component {
    id: mirroredComponent
    NMirroredSpectrum {
      width: parent.width - Style.marginS
      height: parent.height - Style.marginS
      values: SpectrumService.values
      fillColor: ShellColors.mPrimary
      opacity: 0.4
      mirrored: Settings.data.audio.spectrumMirrored
    }
  }

  Component {
    id: waveComponent
    NWaveSpectrum {
      width: parent.width - Style.marginS
      height: parent.height - Style.marginS
      values: SpectrumService.values
      fillColor: ShellColors.mPrimary
      opacity: 0.4
      mirrored: Settings.data.audio.spectrumMirrored
    }
  }
}
