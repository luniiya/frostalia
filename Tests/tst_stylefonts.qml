import QtQuick
import QtTest

TestCase {
  name: "StyleFonts"

  FontLoader {
    id: caelestia
    source: Qt.resolvedUrl("../Assets/Fonts/rubik/Rubik.ttf")
  }

  FontLoader {
    id: material
    source: Qt.resolvedUrl("../Assets/Fonts/roboto/Roboto.ttf")
  }

  function test_bundledFamiliesAreDistinctAndAvailable() {
    tryCompare(caelestia, "status", FontLoader.Ready);
    tryCompare(material, "status", FontLoader.Ready);
    compare(caelestia.name, "Rubik");
    compare(material.name, "Roboto");
    verify(Qt.fontFamilies().indexOf("Rubik") !== -1);
    verify(Qt.fontFamilies().indexOf("Roboto") !== -1);
  }
}
