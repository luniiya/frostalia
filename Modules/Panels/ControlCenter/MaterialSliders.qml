import QtQuick
import QtQuick.Layouts
import "../../../Helpers/ControlCenterLayout.js" as ControlCenterLayout
import qs.Commons
import qs.Services.Hardware
import qs.Services.Media
import qs.Widgets

Rectangle {
  id: root
  property var screen
  property bool showAudio: true
  property bool showBrightness: true
  readonly property var monitor: screen ? BrightnessService.getMonitorForScreen(screen) : null
  readonly property int padding: Math.round(8 * Style.uiScaleRatio)
  implicitHeight: ControlCenterLayout.paddedHeight(sliders.implicitHeight, padding)
  radius: Style.radiusM
  color: Color.mSurfaceVariant

  ColumnLayout {
    id: sliders
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: root.padding
    spacing: Math.round(2 * Style.uiScaleRatio)
    NMaterialQuickSlider {
      id: brightness
      visible: root.showBrightness
      Layout.fillWidth: true
      icon: "brightness-high"
      label: I18n.tr("common.brightness")
      enabled: !!root.monitor && root.monitor.brightnessControlAvailable
      from: 0
      to: 1
      wheelStep: Settings.data.brightness.brightnessStep / 100
      onMoved: if (root.monitor)
                 root.monitor.setBrightness(value)
      Binding {
        target: brightness
        property: "value"
        value: root.monitor?.brightness || 0
        when: !brightness.pressed
      }
    }
    NMaterialQuickSlider {
      id: output
      visible: root.showAudio
      Layout.fillWidth: true
      icon: AudioService.muted ? "volume-off" : "volume-high"
      label: I18n.tr("common.volume")
      enabled: !!AudioService.sink
      from: 0
      to: AudioService.maxVolume
      wheelStep: Settings.data.audio.volumeStep / 100
      fillColor: AudioService.isAboveNormalVolume(value) ? Color.mError : Color.mPrimary
      onMoved: AudioService.setVolume(value)
      onIconClicked: AudioService.setOutputMuted(!AudioService.muted)
      Binding {
        target: output
        property: "value"
        value: AudioService.volume || 0
        when: !output.pressed
      }
    }
    NMaterialQuickSlider {
      id: input
      visible: root.showAudio
      Layout.fillWidth: true
      icon: AudioService.inputMuted ? "microphone-off" : "microphone"
      label: I18n.tr("control-center.microphone")
      enabled: !!AudioService.source
      from: 0
      to: AudioService.maxInputVolume
      wheelStep: Settings.data.audio.volumeStep / 100
      onMoved: AudioService.setInputVolume(value)
      onIconClicked: AudioService.setInputMuted(!AudioService.inputMuted)
      Binding {
        target: input
        property: "value"
        value: AudioService.inputVolume || 0
        when: !input.pressed
      }
    }
  }
}
