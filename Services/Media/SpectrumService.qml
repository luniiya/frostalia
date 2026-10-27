pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../Helpers/UserCount.js" as UserCount
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  // TODO Remove in may 2026
  Component.onCompleted: {
    _setBandsCount();
  }

  // Register a component that needs audio data, call this when a visualizer becomes active.
  // Pass a unique identifier (e.g., "controlcenter:screen1", "plugin:fancy-audiovisualizer")
  function registerComponent(componentId) {
    // Counted, so an id shared by two instances stays until both are gone (UserCount.js)
    root._registeredComponents = UserCount.add(root._registeredComponents, componentId);
    Logger.d("Spectrum", "Component registered:", componentId, "- total:", root._registeredCount);
  }

  // Unregister a component when it no longer needs audio data.
  function unregisterComponent(componentId) {
    root._registeredComponents = UserCount.remove(root._registeredComponents, componentId);
    Logger.d("Spectrum", "Component unregistered:", componentId, "- total:", root._registeredCount);
  }

  // Check if a component is registered
  function isRegistered(componentId) {
    return (root._registeredComponents[componentId] || 0) > 0;
  }

  // Component registration - any component needing audio data registers here
  property var _registeredComponents: ({})
  readonly property int _registeredCount: Object.keys(_registeredComponents).length
  property bool _shouldRun: _registeredCount > 0

  property var values: []
  property bool isIdle: true

  PwAudioSpectrum {
    id: spectrum
    node: Pipewire.defaultAudioSink
    enabled: root._shouldRun
    // TODO Uncomment this in may 2026
    // bandCount: Settings.data.audio.spectrumMirrored ? 32 : 64
    frameRate: Settings.data.audio.spectrumFrameRate
    lowerCutoff: 50
    upperCutoff: 12000
    noiseReduction: 0.77
    smoothing: true

    onValuesChanged: {
      root.values = spectrum.values;
    }

    onIdleChanged: {
      root.isIdle = spectrum.idle;
    }
  }

  // TODO Remove in may 2026 - temporary until noctalia-qs is fully propagated
  Connections {
    target: Settings.data.audio
    function onSpectrumMirroredChanged() {
      _setBandsCount();
    }
  }
  function _setBandsCount() {
    const bandCount = Settings.data.audio.spectrumMirrored ? 32 : 64;
    if (spectrum.bandCount !== undefined) {
      spectrum.bandCount = bandCount;
    } else if (spectrum.barCount !== undefined) {
      spectrum.barCount = bandCount;
    }
  }
}
