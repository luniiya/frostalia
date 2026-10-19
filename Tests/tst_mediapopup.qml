import QtQuick
import QtTest
import "../Helpers/MediaPopup.js" as MediaPopup

TestCase {
  name: "MediaPopup"

  function test_timeLabel_data() {
    return [
          {
            tag: "playing",
            hasPlayer: true,
            position: "2:03",
            length: "2:33",
            expected: "2:03 / 2:33"
          },
          {
            tag: "no player",
            hasPlayer: false,
            position: "2:03",
            length: "2:33",
            expected: ""
          },
          {
            tag: "unknown length",
            hasPlayer: true,
            position: "0:10",
            length: "",
            expected: ""
          },
          {
            tag: "missing position",
            hasPlayer: true,
            position: "",
            length: "3:04",
            expected: "0:00 / 3:04"
          }
        ];
  }

  function test_timeLabel(data) {
    compare(MediaPopup.timeLabel(data.hasPlayer, data.position, data.length), data.expected);
  }

  function test_playButtonMorphs() {
    compare(MediaPopup.playButtonRadius(44, false), 22);
    compare(MediaPopup.playButtonRadius(44, true), 13);
    compare(MediaPopup.playButtonRadius(NaN, true), 0);
  }

  function test_artSizeFollowsHeight() {
    compare(MediaPopup.artSize(400, 132, 12, 160), 108);
  }

  function test_artSizeLeavesRoomForText() {
    compare(MediaPopup.artSize(260, 132, 12, 160), 64);
    compare(MediaPopup.artSize(100, 132, 12, 160), 0);
  }

  function test_backgroundVisualizer() {
    compare(MediaPopup.backgroundVisualizer("linear"), "bars");
    compare(MediaPopup.backgroundVisualizer("wave"), "wave");
    compare(MediaPopup.backgroundVisualizer("mirrored"), "wave");
    compare(MediaPopup.backgroundVisualizer("none"), "");
    compare(MediaPopup.backgroundVisualizer(""), "");
  }
}
