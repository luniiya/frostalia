import QtQuick
import QtTest
import "../Helpers/OsdGeometry.js" as OsdGeometry
import "../Modules/OSD" as Osd

TestCase {
  name: "OsdGeometry"

  function test_progress_data() {
    return [
          {
            tag: "empty",
            value: 0,
            maximum: 1,
            expected: 0
          },
          {
            tag: "half",
            value: 0.5,
            maximum: 1,
            expected: 0.5
          },
          {
            tag: "overdrive",
            value: 1.2,
            maximum: 1.5,
            expected: 0.8
          },
          {
            tag: "negative",
            value: -1,
            maximum: 1,
            expected: 0
          },
          {
            tag: "overflow",
            value: 2,
            maximum: 1,
            expected: 1
          },
          {
            tag: "zero maximum",
            value: 1,
            maximum: 0,
            expected: 0
          },
          {
            tag: "invalid value",
            value: NaN,
            maximum: 1,
            expected: 0
          }
        ];
  }

  function test_progress(data) {
    fuzzyCompare(OsdGeometry.progress(data.value, data.maximum), data.expected, 0.0001);
  }

  function test_trackEndpoints() {
    compare(OsdGeometry.track(200, 26, 0, 1).filled, 0);
    compare(OsdGeometry.track(200, 26, 1, 1).filled, 200);
    compare(OsdGeometry.track(200, 26, 0.01, 1).capsule, 26);
    compare(OsdGeometry.track(0, 26, 1, 1).marker, 0);
    compare(OsdGeometry.track(-1, 26, 1, 1).filled, 0);
  }

  function test_dimensions() {
    compare(OsdGeometry.dimensions(false, false, 1), {
              width: 352,
              height: 112
            });
    compare(OsdGeometry.dimensions(true, false, 1), {
              width: 104,
              height: 296
            });
    compare(OsdGeometry.dimensions(true, true, 1), {
              width: 224,
              height: 92
            });
    compare(OsdGeometry.dimensions(false, true, 2), {
              width: 448,
              height: 184
            });
  }

  Component {
    id: trackComponent
    Osd.MaterialOsdTrack {
      width: 200
      height: 26
      animationDuration: 0
    }
  }

  function test_renderedTrack() {
    const track = createTemporaryObject(trackComponent, this);
    verify(track);
    compare(track.geometry.filled, 0);
    track.value = 0.5;
    tryCompare(track, "displayedFraction", 0.5);
    compare(track.geometry.filled, 100);
    track.maximum = 1.5;
    track.value = 1.5;
    tryCompare(track, "displayedFraction", 1);
    compare(track.geometry.filled, 200);
    track.vertical = true;
    track.width = 48;
    track.height = 220;
    compare(track.geometry.filled, 220);
    track.value = 0;
    tryCompare(track, "displayedFraction", 0);
    compare(track.geometry.filled, 0);
  }
}
