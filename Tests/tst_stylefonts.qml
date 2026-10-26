import QtQuick
import QtTest

TestCase {
  name: "StyleFonts"

  FontLoader {
    id: rubik
    source: Qt.resolvedUrl("../Assets/Fonts/rubik/Rubik.ttf")
  }

  FontLoader {
    id: material
    source: Qt.resolvedUrl("../Assets/Fonts/roboto/Roboto.ttf")
  }

  function test_bundledFamiliesAreDistinctAndAvailable() {
    tryCompare(rubik, "status", FontLoader.Ready);
    tryCompare(material, "status", FontLoader.Ready);
    compare(rubik.name, "Rubik");
    compare(material.name, "Roboto");
    verify(Qt.fontFamilies().indexOf("Rubik") !== -1);
    verify(Qt.fontFamilies().indexOf("Roboto") !== -1);
  }
}
