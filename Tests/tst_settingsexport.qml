import QtQuick
import QtTest
import "../Helpers/SettingsExport.js" as SettingsExport

TestCase {
  name: "SettingsExport"

  function test_localPath_data() {
    return [
          {
            tag: "local file",
            url: "file:///tmp/settings.toml",
            expected: "/tmp/settings.toml"
          },
          {
            tag: "spaces and unicode",
            url: "file:///tmp/my%20settings%20%C3%A9.toml",
            expected: "/tmp/my settings é.toml"
          },
          {
            tag: "literal percent",
            url: "file:///tmp/100%25.toml",
            expected: "/tmp/100%.toml"
          },
          {
            tag: "localhost",
            url: "file://localhost/tmp/export.toml",
            expected: "/tmp/export.toml"
          },
          {
            tag: "remote file",
            url: "file://remote/tmp/export.toml",
            expected: ""
          },
          {
            tag: "web URL",
            url: "https://example.com/export.toml",
            expected: ""
          },
          {
            tag: "malformed escape",
            url: "file:///tmp/%zz.toml",
            expected: ""
          },
          {
            tag: "cancelled",
            url: "",
            expected: ""
          }
        ];
  }

  function test_localPath(data) {
    compare(SettingsExport.localPath(data.url), data.expected);
  }
}
