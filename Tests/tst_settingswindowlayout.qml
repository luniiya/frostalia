import QtQuick
import QtTest
import "../Helpers/SettingsWindowLayout.js" as SettingsWindowLayout

TestCase {
  name: "SettingsWindowLayout"

  function test_window_data() {
    return [
          {
            tag: "Caelestia unchanged",
            material: false,
            scale: 1,
            width: 840,
            height: 910,
            minimumWidth: 840,
            minimumHeight: 910
          },
          {
            tag: "Caelestia scaled",
            material: false,
            scale: 1.25,
            width: 1050,
            height: 1138,
            minimumWidth: 1050,
            minimumHeight: 1138
          },
          {
            tag: "Material landscape",
            material: true,
            scale: 1,
            width: 1100,
            height: 750,
            minimumWidth: 760,
            minimumHeight: 520
          },
          {
            tag: "Material accessibility scale",
            material: true,
            scale: 1.5,
            width: 1650,
            height: 1125,
            minimumWidth: 1140,
            minimumHeight: 780
          }
        ];
  }

  function test_window(data) {
    const metrics = SettingsWindowLayout.windowMetrics(data.material, data.scale);
    compare(metrics.width, data.width);
    compare(metrics.height, data.height);
    compare(metrics.minimumWidth, data.minimumWidth);
    compare(metrics.minimumHeight, data.minimumHeight);
    verify(metrics.minimumWidth <= metrics.width);
    verify(metrics.minimumHeight <= metrics.height);
  }

  function test_rail_data() {
    return [
          {
            tag: "compact",
            expanded: false,
            scale: 1,
            width: 56,
            height: 44
          },
          {
            tag: "expanded",
            expanded: true,
            scale: 1,
            width: 224,
            height: 44
          },
          {
            tag: "compact scaled",
            expanded: false,
            scale: 1.5,
            width: 84,
            height: 66
          },
          {
            tag: "expanded scaled",
            expanded: true,
            scale: 1.5,
            width: 336,
            height: 66
          }
        ];
  }

  function test_rail(data) {
    const rail = SettingsWindowLayout.materialRail(data.expanded, data.scale);
    compare(rail.width, data.width);
    compare(rail.rowHeight, data.height);
  }

  function test_search_data() {
    return [
          {
            tag: "wide window caps search",
            width: 1084,
            controls: 40,
            scale: 1,
            expected: 360
          },
          {
            tag: "narrow window reserves controls on both sides",
            width: 400,
            controls: 40,
            scale: 1,
            expected: 288
          },
          {
            tag: "scaled titlebar",
            width: 600,
            controls: 60,
            scale: 1.5,
            expected: 432
          },
          {
            tag: "no negative width before layout",
            width: 0,
            controls: 40,
            scale: 1,
            expected: 0
          }
        ];
  }

  function test_search(data) {
    compare(SettingsWindowLayout.searchWidth(data.width, data.controls, data.scale), data.expected);
  }

  function test_directNavigation_data() {
    return [
          {
            tag: "home forward",
            index: 7,
            count: 20,
            home: true,
            direction: 1,
            expected: 0
          },
          {
            tag: "home backward",
            index: 0,
            count: 20,
            home: true,
            direction: -1,
            expected: 19
          },
          {
            tag: "next category",
            index: 3,
            count: 20,
            home: false,
            direction: 1,
            expected: 4
          },
          {
            tag: "previous category",
            index: 3,
            count: 20,
            home: false,
            direction: -1,
            expected: 2
          },
          {
            tag: "wrap forward",
            index: 19,
            count: 20,
            home: false,
            direction: 1,
            expected: 0
          },
          {
            tag: "wrap backward",
            index: 0,
            count: 20,
            home: false,
            direction: -1,
            expected: 19
          },
          {
            tag: "empty model",
            index: 0,
            count: 0,
            home: true,
            direction: 1,
            expected: -1
          }
        ];
  }

  function test_directNavigation(data) {
    compare(SettingsWindowLayout.adjacentTab(data.index, data.count, data.home, data.direction), data.expected);
  }

  function test_homeMetrics_data() {
    return [
          {
            tag: "Material normal window",
            width: 850,
            scale: 1,
            material: true,
            contentWidth: 850,
            avatar: 56
          },
          {
            tag: "Material ultrawide",
            width: 2400,
            scale: 1,
            material: true,
            contentWidth: 960,
            avatar: 56
          },
          {
            tag: "Material narrow",
            width: 480,
            scale: 1,
            material: true,
            contentWidth: 480,
            avatar: 56
          },
          {
            tag: "Material scaled ultrawide",
            width: 3000,
            scale: 1.5,
            material: true,
            contentWidth: 1440,
            avatar: 84
          },
          {
            tag: "Caelestia ultrawide",
            width: 1200,
            scale: 1,
            material: false,
            contentWidth: 900,
            avatar: 56
          },
          {
            tag: "Caelestia normal window",
            width: 540,
            scale: 1,
            material: false,
            contentWidth: 540,
            avatar: 56
          },
          {
            tag: "Caelestia narrow",
            width: 300,
            scale: 1,
            material: false,
            contentWidth: 300,
            avatar: 56
          },
          {
            tag: "Caelestia scaled ultrawide",
            width: 3000,
            scale: 1.5,
            material: false,
            contentWidth: 1350,
            avatar: 84
          },
          {
            tag: "initial layout",
            width: 0,
            scale: 1,
            material: true,
            contentWidth: 0,
            avatar: 56
          }
        ];
  }

  function test_homeMetrics(data) {
    const metrics = SettingsWindowLayout.homeMetrics(data.width, data.scale, data.material);
    compare(metrics.contentWidth, data.contentWidth);
    compare(metrics.avatarSize, data.avatar);
    verify(metrics.contentWidth <= data.width);
    const grid = SettingsWindowLayout.homeGrid(metrics.contentWidth, data.scale, data.material);
    if (data.material && data.width >= 960 * data.scale) {
      compare(grid.columns, 3);
      verify(grid.cardWidth <= 320 * data.scale);
    }
    if (!data.material && data.width >= 900 * data.scale) {
      compare(grid.columns, 3);
      verify(grid.cardWidth <= 300 * data.scale);
    }
    verify(metrics.avatarSize + 32 * data.scale < (data.material ? 112 : 100) * data.scale, "profile with padding is shorter than category cards");
  }

  function test_homeGrid_data() {
    return [
          {
            tag: "Material desktop",
            width: 780,
            scale: 1,
            material: true,
            columns: 3
          },
          {
            tag: "Material narrow window",
            width: 500,
            scale: 1,
            material: true,
            columns: 2
          },
          {
            tag: "Caelestia home",
            width: 540,
            scale: 1,
            material: false,
            columns: 3
          },
          {
            tag: "Caelestia narrow",
            width: 300,
            scale: 1,
            material: false,
            columns: 1
          },
          {
            tag: "Caelestia two-column fallback",
            width: 500,
            scale: 1,
            material: false,
            columns: 2
          },
          {
            tag: "Caelestia scaled home",
            width: 810,
            scale: 1.5,
            material: false,
            columns: 3
          },
          {
            tag: "scaled accessibility",
            width: 780,
            scale: 1.5,
            material: true,
            columns: 2
          },
          {
            tag: "before initial layout",
            width: 0,
            scale: 1,
            material: true,
            columns: 1
          }
        ];
  }

  function test_homeGrid(data) {
    const grid = SettingsWindowLayout.homeGrid(data.width, data.scale, data.material);
    compare(grid.columns, data.columns);
    verify(grid.cardWidth >= 0);
    compare(grid.cardWidth * grid.columns + grid.spacing * (grid.columns - 1), data.width);
  }

  function test_profile_data() {
    return [
          {
            tag: "real name and OS",
            displayName: "Aya",
            username: "ayaya",
            os: "CachyOS",
            name: "Aya",
            expectedOs: "CachyOS"
          },
          {
            tag: "username fallback",
            displayName: "",
            username: "ayaya",
            os: "",
            name: "ayaya",
            expectedOs: "Operating system"
          },
          {
            tag: "trim metadata",
            displayName: "  Aya  ",
            username: "user",
            os: "  Linux  ",
            name: "Aya",
            expectedOs: "Linux"
          },
          {
            tag: "unknown metadata stays neutral",
            displayName: " ",
            username: "",
            os: " ",
            name: "",
            expectedOs: "Operating system"
          }
        ];
  }

  function test_profile(data) {
    const profile = SettingsWindowLayout.profile(data.displayName, data.username, data.os, "Operating system");
    compare(profile.name, data.name);
    compare(profile.os, data.expectedOs);
  }
}
