import QtQuick
import QtTest
import "../Helpers/SettingsWindowLayout.js" as SettingsWindowLayout

TestCase {
  name: "SettingsWindowLayout"

  function test_window_data() {
    return [
          {
            tag: "Caelestia two-column minimum",
            material: false,
            scale: 1,
            width: 840,
            height: 910,
            minimumWidth: 500,
            minimumHeight: 910
          },
          {
            tag: "Caelestia scaled",
            material: false,
            scale: 1.25,
            width: 1050,
            height: 1138,
            minimumWidth: 625,
            minimumHeight: 1138
          },
          {
            tag: "Material landscape",
            material: true,
            scale: 1,
            width: 1100,
            height: 750,
            minimumWidth: 560,
            minimumHeight: 520
          },
          {
            tag: "Material accessibility scale",
            material: true,
            scale: 1.5,
            width: 1650,
            height: 1125,
            minimumWidth: 840,
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

  function test_minimumWindowFitsTwoCards_data() {
    return [
          {
            tag: "Caelestia",
            material: false,
            scale: 1
          },
          {
            tag: "Caelestia scaled",
            material: false,
            scale: 1.25
          },
          {
            tag: "Material",
            material: true,
            scale: 1
          },
          {
            tag: "Material scaled",
            material: true,
            scale: 1.5
          }
        ];
  }

  function test_minimumWindowFitsTwoCards(data) {
    const window = SettingsWindowLayout.windowMetrics(data.material, data.scale);
    const outerMargin = Math.round((data.material ? 8 : 13) * data.scale);
    const homePadding = Math.round((data.material ? 24 : 13) * data.scale);
    const width = window.minimumWidth - 2 * (outerMargin + homePadding);
    const grid = SettingsWindowLayout.homeGrid(width, data.scale, data.material);
    compare(grid.columns, 2);
    verify(grid.cardWidth >= Math.round((data.material ? 210 : 160) * data.scale));
  }

  function test_rail_data() {
    return [
          {
            tag: "compact",
            expanded: false,
            scale: 1,
            width: 44,
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
            width: 66,
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
    compare(rail.rowSpacing, Math.round(5 * data.scale));
    verify(rail.rowSpacing > 0 && rail.rowSpacing < rail.rowHeight / 5);
    if (!data.expanded)
      compare(rail.width, rail.rowHeight, "compact buttons are square");
  }

  function test_railScrollbarGutter_data() {
    return [
          {
            tag: "compact",
            expanded: false,
            scale: 1,
            gutter: 10
          },
          {
            tag: "expanded",
            expanded: true,
            scale: 1,
            gutter: 10
          },
          {
            tag: "compact scaled",
            expanded: false,
            scale: 1.5,
            gutter: 15
          },
          {
            tag: "expanded scaled",
            expanded: true,
            scale: 1.5,
            gutter: 15
          }
        ];
  }

  function test_railScrollbarGutter(data) {
    const base = SettingsWindowLayout.materialRail(data.expanded, data.scale);
    const scrolling = SettingsWindowLayout.materialRail(data.expanded, data.scale, data.gutter);
    compare(scrolling.width - data.gutter, base.width);
    compare(scrolling.rowHeight, base.rowHeight);
    if (!data.expanded)
      compare(scrolling.width - data.gutter, scrolling.rowHeight, "scrollbar does not distort compact buttons");
    compare(SettingsWindowLayout.materialRail(data.expanded, data.scale, 0).width, base.width);
  }

  function test_railTransition_data() {
    return [
          {
            tag: "compact",
            progress: 0,
            width: 44
          },
          {
            tag: "opening",
            progress: 0.25,
            width: 89
          },
          {
            tag: "midpoint",
            progress: 0.5,
            width: 134
          },
          {
            tag: "expanded",
            progress: 1,
            width: 224
          }
        ];
  }

  function test_railTransition(data) {
    const rail = SettingsWindowLayout.materialRail(data.progress, 1, 10);
    compare(rail.width, data.width + 10);
    compare(rail.rowHeight, 44);
    const inset = SettingsWindowLayout.railIconInset(data.progress, 44, 24, 16);
    compare(inset, 10 + 6 * data.progress);
  }

  function test_compactIconIsCenteredAtEveryScale() {
    for (const scale of [1, 1.25, 1.5, 2]) {
      const rail = SettingsWindowLayout.materialRail(false, scale);
      const iconWidth = 24 * scale;
      const inset = SettingsWindowLayout.railIconInset(0, rail.rowHeight, iconWidth, 16 * scale);
      compare(inset * 2 + iconWidth, rail.width);
    }
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
    const span = Math.min(2, grid.columns);
    compare(grid.profileWidth, grid.cardWidth * span + grid.spacing * (span - 1));
    verify(grid.profileWidth <= data.width);
    if (grid.columns <= 2)
      compare(grid.profileWidth, data.width);
  }

  function test_escapeAction_data() {
    return [
          {
            tag: "search on home",
            search: "weather",
            home: true,
            action: "clearSearch"
          },
          {
            tag: "search in category",
            search: "weather",
            home: false,
            action: "clearSearch"
          },
          {
            tag: "whitespace search",
            search: " ",
            home: false,
            action: "clearSearch"
          },
          {
            tag: "category returns home",
            search: "",
            home: false,
            action: "home"
          },
          {
            tag: "home closes",
            search: "",
            home: true,
            action: "close"
          }
        ];
  }

  function test_escapeAction(data) {
    compare(SettingsWindowLayout.escapeAction(data.search, data.home), data.action);
  }

  function test_homeCategories_data() {
    return [
          {
            tag: "wide",
            wide: true,
            missingAbout: false,
            promoted: true
          },
          {
            tag: "narrow keeps every category",
            wide: false,
            missingAbout: false,
            promoted: false
          },
          {
            tag: "missing side category",
            wide: true,
            missingAbout: true,
            promoted: false
          }
        ];
  }

  function test_homeCategories(data) {
    const tabs = [
            {
              id: 20
            },
            {
              id: 9
            },
            {
              id: 4
            }
          ];
    if (!data.missingAbout)
      tabs.push({
                  id: 0
                });
    const snapshot = JSON.stringify(tabs);
    const result = SettingsWindowLayout.homeCategories(tabs, 9, 0, data.wide);
    compare(result.promoted, data.promoted);
    compare(result.general.index, 1);
    if (data.promoted) {
      compare(result.about.index, 3);
      compare(result.grid.map(entry => entry.index), [0, 2]);
      compare(result.grid.map(entry => entry.tab.id), [20, 4]);
    } else {
      compare(result.grid.map(entry => entry.tab), tabs);
    }
    compare(JSON.stringify(tabs), snapshot);
  }

  function test_profile_data() {
    return [
          {
            tag: "username takes precedence",
            displayName: "Aya",
            username: "ayaya",
            os: "CachyOS",
            hostname: "cubeberry",
            expectedHostname: "cubeberry",
            name: "ayaya",
            expectedOs: "CachyOS"
          },
          {
            tag: "username fallback",
            displayName: "",
            username: "ayaya",
            os: "",
            hostname: "",
            expectedHostname: "",
            name: "ayaya",
            expectedOs: "Operating system"
          },
          {
            tag: "trim metadata",
            displayName: "  Aya  ",
            username: "user",
            os: "  Linux  ",
            hostname: "  cubeberry  ",
            expectedHostname: "cubeberry",
            name: "user",
            expectedOs: "Linux"
          },
          {
            tag: "unknown metadata stays neutral",
            displayName: " ",
            username: "",
            os: " ",
            hostname: undefined,
            expectedHostname: "",
            name: "",
            expectedOs: "Operating system"
          }
        ];
  }

  function test_profile(data) {
    const profile = SettingsWindowLayout.profile(data.displayName, data.username, data.os, "Operating system", data.hostname);
    compare(profile.name, data.name);
    compare(profile.os, data.expectedOs);
    compare(profile.hostname, data.expectedHostname);
    compare(SettingsWindowLayout.profile("", "", "", "Operating system").hostname, "");
  }
}
