import QtQuick
import QtTest
import "../Helpers/BubbleLogic.js" as Bubbles

TestCase {
  id: testCase
  name: "BubbleForeground"
  width: 80
  height: 48
  visible: true
  when: windowShown

  Rectangle {
    anchors.fill: parent
    color: "black"
  }

  Item {
    id: viewport
    anchors.fill: parent
    property var bubbleContext: ({
                                   oledMode: true
                                 })

    Item {
      x: 8
      y: 8
      width: 48
      height: 32

      Text {
        id: label
        anchors.centerIn: parent
        text: "Hi"
        color: "#123456"
        font.pixelSize: 24

        Binding {
          target: label
          property: "color"
          value: "white"
          when: Bubbles.isOledItem(label)
        }
      }
    }
  }

  function test_textIsWhiteAndNormalColorRestores() {
    compare(label.color.toString(), "#ffffff");
    var image = grabImage(testCase);
    var whitePixels = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var pixel = image.pixel(x, y);
        if (pixel.r > 0.95 && pixel.g > 0.95 && pixel.b > 0.95)
          whitePixels++;
      }
    }
    verify(whitePixels > 10);
    viewport.bubbleContext = {
      oledMode: false
    };
    compare(label.color.toString(), "#123456");
  }
}
