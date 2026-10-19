import QtQuick
import QtTest

TestCase {
  name: "ShellLogo"

  Image {
    id: logo
    source: "../Assets/frostalia.svg"
    width: 96
    height: 96
    sourceSize: Qt.size(96, 96)
    fillMode: Image.PreserveAspectFit
  }

  function test_snowflakeLoadsAtShellLogoSize() {
    tryCompare(logo, "status", Image.Ready);
    compare(logo.sourceSize.width, 96);
    compare(logo.sourceSize.height, 96);
  }
}
