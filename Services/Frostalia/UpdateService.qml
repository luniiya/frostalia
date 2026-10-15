pragma Singleton

import QtQuick
import Quickshell
import "../../Helpers/VersionComparison.js" as VersionComparison
import qs.Commons

Singleton {
  id: root

  // Plugin manifests use the inherited API version for compatibility checks.
  readonly property string baseVersion: "4.7.8"
  readonly property bool isDevelopment: true
  readonly property string developmentSuffix: "-git"
  readonly property string currentVersion: `v${!isDevelopment ? baseVersion : baseVersion + developmentSuffix}`
  readonly property string releasesUrl: "https://github.com/luniiya/frostalia/releases"

  function init() {
    Logger.i("UpdateService", "Version:", root.currentVersion);
  }

  function compareVersions(a, b) {
    return VersionComparison.compareVersions(a, b);
  }

  // Release notes are opened only by an explicit user action.
  function viewChangelog() {
    Quickshell.execDetached(["xdg-open", releasesUrl]);
  }
}
