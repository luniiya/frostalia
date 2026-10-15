import QtQuick
import QtTest
import "../Helpers/VersionDisplay.js" as VersionDisplay

TestCase {
  name: "VersionDisplay"

  function test_installedVersion_data() {
    return [
          {
            tag: "git checkout",
            version: "v4.7.8-git",
            commit: "3b7dd76",
            expected: "3b7dd76"
          },
          {
            tag: "commit loading",
            version: "v4.7.8-git",
            commit: "",
            expected: "v4.7.8-git"
          },
          {
            tag: "release",
            version: "v4.7.8",
            commit: "",
            expected: "v4.7.8"
          }
        ];
  }

  function test_installedVersion(data) {
    compare(VersionDisplay.installedVersion(data.version, data.commit), data.expected);
  }
}
