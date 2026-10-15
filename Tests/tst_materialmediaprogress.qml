import QtQuick
import QtQuick.Controls
import QtTest
import "../Helpers/MaterialMediaProgress.js" as Progress
import "../Widgets" as Widgets

TestCase {
  name: "MaterialMediaProgress"
  visible: true
  when: windowShown
  width: 320
  height: 100

  function test_playedSegmentOnly() {
    const points = Progress.points(200, 28, 0.4, 3, 20, 0.6);
    compare(points[0], {
              x: 0,
              y: 14
            });
    fuzzyCompare(points[points.length - 1].x, 80, 0.001);
    fuzzyCompare(points[points.length - 1].y, 14, 0.001);
    verify(points.some(point => Math.abs(point.y - 14) > 1));
    verify(points.every(point => point.x >= 0 && point.x <= 80 && point.y >= 11 && point.y <= 17));
    verify(Progress.path(points) !== Progress.path(Progress.points(200, 28, 0.4, 3, 20, 1.6)));
  }

  function test_waveKeepsItsHeightAtNormalPlaybackProgress() {
    const points = Progress.points(440, 28, 0.4, 4, 28, 0);
    // Endpoint easing must not flatten most of the played portion.
    const middle = points.filter(point => point.x > 20 && point.x < 150);
    verify(middle.some(point => point.y > 17.5));
    verify(middle.some(point => point.y < 10.5));
  }

  function test_pausedStraight() {
    compare(Progress.points(200, 28, 0.5, 0, 20, 1), [
              {
                x: 0,
                y: 14
              },
              {
                x: 100,
                y: 14
              }
            ]);
  }

  function test_boundaries() {
    compare(Progress.points(200, 28, 0, 3, 20, 0), []);
    compare(Progress.points(200, 28, NaN, 3, 20, 0), []);
    compare(Progress.points(-2, 28, 1, 3, 20, 0), []);
    const points = Progress.points(200, 28, 2, 100, NaN, NaN);
    compare(points[points.length - 1].x, 200);
    verify(points.every(point => Number.isFinite(point.y) && point.y >= 0 && point.y <= 28));
  }

  Component {
    id: sliderComponent
    Widgets.NMaterialMediaSlider {
      width: 240
      height: 28
      value: 0.4
    }
  }
  SignalSpy {
    id: movedSpy
    signalName: "moved"
  }

  function test_playPauseAndReducedMotion() {
    const slider = createTemporaryObject(sliderComponent, this);
    verify(slider);
    compare(slider.amplitude, 0);
    slider.playing = true;
    tryCompare(slider, "waving", true);
    tryCompare(slider, "amplitude", 4);
    const initialPhase = slider.phase;
    wait(60);
    verify(slider.phase !== initialPhase);
    slider.playing = false;
    tryCompare(slider, "amplitude", 0);
    compare(slider.wavePoints.length, 2);
    slider.playing = true;
    slider.motionEnabled = false;
    compare(slider.waving, false);
    tryCompare(slider, "amplitude", 0);
    compare(slider.value, 0.4);
  }

  function test_nativeKeyboardSeeking() {
    const slider = createTemporaryObject(sliderComponent, this);
    movedSpy.target = slider;
    movedSpy.clear();
    slider.forceActiveFocus();
    keyClick(Qt.Key_Right);
    verify(slider.value > 0.4);
    compare(movedSpy.count, 1);
    slider.enabled = false;
    const value = slider.value;
    keyClick(Qt.Key_Right);
    compare(slider.value, value);
    movedSpy.target = null;
  }
}
