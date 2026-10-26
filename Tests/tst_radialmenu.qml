import QtQuick
import QtTest
import "../Helpers/RadialMenu.js" as RadialMenu
import "../Helpers/UiStyles.js" as UiStyles

TestCase {
  name: "RadialMenu"

  readonly property var tree: [
    {
      "action": "editDesktop"
    },
    {
      "action": "settings"
    },
    {
      "action": "folder",
      "labelKey": "radial-menu.items.apps",
      "icon": "apps",
      "children": [
        {
          "action": "app",
          "arg": "kitty"
        },
        {
          "action": "app",
          "arg": "firefox"
        }
      ]
    },
    {
      "action": "lock"
    }
  ]

  readonly property var opts: ({
                                 "width": 1000,
                                 "height": 800,
                                 "deadZone": 40,
                                 "maxRadius": 150,
                                 "descendRadius": 110,
                                 "dragThreshold": 20,
                                 "reach": 130,
                                 "margin": 10,
                                 "itemRadius": 90
                               })

  function fuzzy(actual, expected, tag) {
    verify(Math.abs(actual - expected) < 1e-6, (tag || "") + ": " + actual + " != " + expected);
  }

  function test_angleOf_data() {
    return [
          {
            tag: "up",
            dx: 0,
            dy: -10,
            angle: 0
          },
          {
            tag: "right",
            dx: 10,
            dy: 0,
            angle: 90
          },
          {
            tag: "down",
            dx: 0,
            dy: 10,
            angle: 180
          },
          {
            tag: "left",
            dx: -10,
            dy: 0,
            angle: 270
          },
          {
            tag: "up-right",
            dx: 10,
            dy: -10,
            angle: 45
          }
        ];
  }

  function test_angleOf(data) {
    fuzzy(RadialMenu.angleOf(data.dx, data.dy), data.angle, data.tag);
  }

  function test_wedgeIndex_data() {
    return [
          {
            tag: "first wedge is centered on up",
            angle: 0,
            count: 4,
            index: 0
          },
          {
            tag: "just left of up is still first",
            angle: 350,
            count: 4,
            index: 0
          },
          {
            tag: "boundary goes to the next wedge",
            angle: 45,
            count: 4,
            index: 1
          },
          {
            tag: "down is the third of four",
            angle: 180,
            count: 4,
            index: 2
          },
          {
            tag: "last wedge",
            angle: 300,
            count: 4,
            index: 3
          },
          {
            tag: "negative angles wrap",
            angle: -90,
            count: 4,
            index: 3
          },
          {
            tag: "single item takes everything",
            angle: 200,
            count: 1,
            index: 0
          },
          {
            tag: "empty ring",
            angle: 0,
            count: 0,
            index: -1
          },
          {
            tag: "six items",
            angle: 125,
            count: 6,
            index: 2
          }
        ];
  }

  function test_wedgeIndex(data) {
    compare(RadialMenu.wedgeIndex(data.angle, data.count), data.index);
  }

  function test_hitTest_data() {
    return [
          {
            tag: "dead zone",
            dx: 5,
            dy: -5,
            index: -1
          },
          {
            tag: "up beyond dead zone",
            dx: 0,
            dy: -60,
            index: 0
          },
          {
            tag: "right",
            dx: 60,
            dy: 0,
            index: 1
          },
          {
            tag: "beyond max radius",
            dx: 0,
            dy: 200,
            max: 150,
            index: -1
          },
          {
            tag: "direction only without max radius",
            dx: 0,
            dy: 2000,
            max: Infinity,
            index: 2
          }
        ];
  }

  function test_hitTest(data) {
    compare(RadialMenu.hitTest(data.dx, data.dy, 4, 40, data.max), data.index);
  }

  function test_layoutPlacesItemsClockwiseFromTop() {
    const items = RadialMenu.layout(4, 100);
    compare(items.length, 4);
    fuzzy(items[0].x, 0, "top x");
    fuzzy(items[0].y, -100, "top y");
    fuzzy(items[1].x, 100, "right x");
    fuzzy(items[1].y, 0, "right y");
    fuzzy(items[2].y, 100, "bottom y");
    fuzzy(items[3].x, -100, "left x");
    compare(items[3].angle, 270);
  }

  function test_wedgeShapeKeepsConstantGap() {
    const shape = RadialMenu.wedgeShape(0, 4, 50, 130, 10, 0);
    verify(shape !== null);
    // The wedge is centered on up: its edges mirror each other and sit gap/2 from the boundary
    fuzzy(shape.outerStart.x, -shape.outerEnd.x, "symmetric");
    fuzzy(shape.outerStart.y, shape.outerEnd.y, "symmetric y");
    // The boundary between wedge 0 and 1 is the 45 degree line; distance to it is gap/2
    const distance = (p => Math.abs(p.x + p.y) / Math.SQRT2);
    fuzzy(distance(shape.outerEnd), 5, "outer gap");
    fuzzy(distance(shape.innerEnd), 5, "inner gap");
    fuzzy(Math.hypot(shape.outerEnd.x, shape.outerEnd.y), 130, "outer radius");
    fuzzy(Math.hypot(shape.innerStart.x, shape.innerStart.y), 50, "inner radius");
    verify(!shape.outerLarge);
  }

  function test_wedgeShapeInsetShrinksEverySide() {
    const shape = RadialMenu.wedgeShape(1, 4, 50, 130, 10, 6);
    fuzzy(shape.outerRadius, 124, "outer");
    fuzzy(shape.innerRadius, 56, "inner");
    fuzzy(shape.centerAngle, 90, "angle");
  }

  function test_wedgeShapeSingleItemIsLargeArc() {
    const shape = RadialMenu.wedgeShape(0, 1, 50, 130, 8, 0);
    verify(shape.outerLarge);
    verify(shape.innerLarge);
  }

  function test_wedgeShapeDegenerate() {
    compare(RadialMenu.wedgeShape(0, 4, 50, 40, 6, 0), null);
    compare(RadialMenu.wedgeShape(0, 0, 50, 130, 6, 0), null);
    compare(RadialMenu.wedgeShape(0, 12, 4, 130, 20, 0), null);
  }

  function test_clampCenter_data() {
    return [
          {
            tag: "inside stays",
            x: 500,
            y: 400,
            ex: 500,
            ey: 400
          },
          {
            tag: "top-left corner",
            x: 3,
            y: 5,
            ex: 140,
            ey: 140
          },
          {
            tag: "bottom-right corner",
            x: 999,
            y: 790,
            ex: 860,
            ey: 660
          }
        ];
  }

  function test_clampCenter(data) {
    const c = RadialMenu.clampCenter(data.x, data.y, 1000, 800, 130, 10);
    compare(c.x, data.ex);
    compare(c.y, data.ey);
  }

  function test_clampCenterOnTinyScreenCenters() {
    const c = RadialMenu.clampCenter(10, 10, 200, 200, 130, 10);
    compare(c.x, 100);
    compare(c.y, 100);
  }

  function test_normalizeDropsInvalidEntries() {
    const items = RadialMenu.normalizeItems([null, 3,
                                             {
                                               "action": "nope"
                                             },
                                             {
                                               "action": "lock",
                                               "label": 5
                                             },
                                             {
                                               "action": "folder",
                                               "children": [
                                                 {
                                                   "action": "bogus"
                                                 },
                                                 {
                                                   "action": "settings"
                                                 }
                                               ]
                                             }
                                            ]);
    compare(items.length, 2);
    compare(items[0].action, "lock");
    compare(items[0].label, "");
    compare(items[1].children.length, 1);
    compare(items[1].children[0].action, "settings");
    verify(items[0].children === undefined);
  }

  function test_normalizeCapsRingSizeAndDepth() {
    const many = [];
    for (let i = 0; i < 20; i++)
      many.push({
                  "action": "lock"
                });
    compare(RadialMenu.normalizeItems(many).length, RadialMenu.maxItemsPerRing);
    let deep = [
          {
            "action": "lock"
          }
        ];
    for (let d = 0; d < 6; d++)
      deep = [
            {
              "action": "folder",
              "children": deep
            }
          ];
    let depth = 0;
    let ring = RadialMenu.normalizeItems(deep);
    while (ring.length > 0 && ring[0].action === "folder") {
      depth++;
      ring = ring[0].children;
    }
    verify(depth <= RadialMenu.maxDepth - 1, "depth " + depth);
  }

  function test_normalizeAcceptsArrayLikeLists() {
    const listLike = {
      "length": 1,
      "0": {
        "action": "settings"
      }
    };
    compare(RadialMenu.normalizeItems(listLike).length, 1);
    compare(RadialMenu.normalizeItems(undefined).length, 0);
  }

  function test_itemsAtFollowsPath() {
    compare(RadialMenu.itemsAt(tree, []).length, 4);
    compare(RadialMenu.itemsAt(tree, [2]).length, 2);
    compare(RadialMenu.itemsAt(tree, [2])[1].arg, "firefox");
    compare(RadialMenu.itemsAt(tree, [0]).length, 0);
    compare(RadialMenu.itemsAt(tree, [9]).length, 0);
  }

  function test_labelsAndIcons() {
    compare(RadialMenu.labelKeyFor({
                                     "action": "lock",
                                     "label": ""
                                   }), "radial-menu.actions.lock");
    compare(RadialMenu.labelKeyFor({
                                     "action": "lock",
                                     "label": "Bye"
                                   }), "");
    compare(RadialMenu.labelKeyFor(tree[2]), "radial-menu.items.apps");
    compare(RadialMenu.labelKeyFor({
                                     "action": "app",
                                     "arg": "kitty"
                                   }), "");
    compare(RadialMenu.iconFor({
                                 "action": "settings"
                               }), "settings");
    compare(RadialMenu.iconFor(tree[2]), "apps");
  }

  function test_everyActionHasLabelAndIcon() {
    const ids = RadialMenu.actionIds();
    verify(ids.indexOf("editDesktop") >= 0);
    verify(ids.indexOf("sessionMenu") >= 0);
    for (const id of ids) {
      verify(RadialMenu.actions[id].labelKey.indexOf("radial-menu.actions.") === 0, id);
      verify(RadialMenu.actions[id].icon.length > 0, id);
    }
  }

  // --- state machine

  function test_openClampsCenterAndStartsHeld() {
    const s = RadialMenu.open(5, 400, opts);
    compare(s.centers[0].x, 140);
    compare(s.centers[0].y, 400);
    verify(s.held);
    compare(s.path.length, 0);
  }

  function test_quickRightClickStaysOpenInClickMode() {
    const s = RadialMenu.open(500, 400, opts);
    const r = RadialMenu.release(s, 502, 401, tree, opts);
    verify(r.state !== null);
    verify(!r.state.held);
    compare(r.activate, null);
  }

  function test_flickSelectsByDirection() {
    let s = RadialMenu.open(500, 400, opts);
    s = RadialMenu.move(s, 560, 400, tree, opts);
    compare(s.hovered, 1);
    verify(s.dragged);
    const r = RadialMenu.release(s, 570, 402, tree, opts);
    compare(r.state, null);
    compare(r.activate.action, "settings");
  }

  function test_flickWorksFarBeyondTheRing() {
    let s = RadialMenu.open(500, 400, opts);
    const r = RadialMenu.release(RadialMenu.move(s, 500, 50, tree, opts), 500, 10, tree, opts);
    compare(r.activate.action, "editDesktop");
  }

  function test_releaseInDeadZoneAfterDragStaysOpen() {
    let s = RadialMenu.open(500, 400, opts);
    s = RadialMenu.move(s, 560, 400, tree, opts);
    const r = RadialMenu.release(s, 505, 400, tree, opts);
    verify(r.state !== null);
    compare(r.activate, null);
  }

  function test_dragThroughFolderOpensSubRingAtPointer() {
    let s = RadialMenu.open(500, 400, opts);
    // Folder is wedge 2 (down)
    s = RadialMenu.move(s, 500, 470, tree, opts);
    compare(s.hovered, 2);
    compare(s.path.length, 0);
    s = RadialMenu.move(s, 500, 520, tree, opts);
    compare(s.path, [2]);
    compare(s.centers[1].x, 500);
    compare(s.centers[1].y, 520);
    // Continue the stroke downwards: the second of two apps
    s = RadialMenu.move(s, 500, 600, tree, opts);
    compare(s.hovered, 1);
    const r = RadialMenu.release(s, 500, 610, tree, opts);
    compare(r.activate.arg, "firefox");
  }

  function test_flickReleasedOnFolderOpensIt() {
    let s = RadialMenu.open(500, 400, opts);
    s = RadialMenu.move(s, 500, 460, tree, opts);
    const r = RadialMenu.release(s, 500, 470, tree, opts);
    compare(r.activate, null);
    compare(r.state.path, [2]);
    verify(!r.state.held);
  }

  function test_clickModeClickPicksWedge() {
    let s = RadialMenu.release(RadialMenu.open(500, 400, opts), 500, 400, tree, opts).state;
    s = RadialMenu.move(s, 500, 310, tree, opts);
    compare(s.hovered, 0);
    const r = RadialMenu.click(s, 500, 310, tree, opts);
    compare(r.activate.action, "editDesktop");
    compare(r.state, null);
  }

  function test_clickOutsideCloses() {
    const s = RadialMenu.release(RadialMenu.open(500, 400, opts), 500, 400, tree, opts).state;
    compare(RadialMenu.move(s, 500, 100, tree, opts).hovered, -1);
    const r = RadialMenu.click(s, 500, 100, tree, opts);
    compare(r.state, null);
    compare(r.activate, null);
  }

  function test_clickFolderOpensAroundItemAndCenterGoesBack() {
    const s = RadialMenu.release(RadialMenu.open(500, 400, opts), 500, 400, tree, opts).state;
    const opened = RadialMenu.click(s, 500, 480, tree, opts);
    compare(opened.state.path, [2]);
    compare(opened.state.centers[1].x, 500);
    compare(opened.state.centers[1].y, 490);
    const back = RadialMenu.click(opened.state, 500, 490, tree, opts);
    compare(back.state.path.length, 0);
    compare(back.state.centers.length, 1);
    const closed = RadialMenu.click(back.state, 500, 400, tree, opts);
    compare(closed.state, null);
  }

  function test_backAtRootCloses() {
    compare(RadialMenu.back(RadialMenu.open(500, 400, opts)), null);
  }

  function test_pickByIndex() {
    const s = RadialMenu.open(500, 400, opts);
    compare(RadialMenu.pick(s, 3, tree, opts).activate.action, "lock");
    compare(RadialMenu.pick(s, 7, tree, opts).state, s);
  }

  function test_stateIsNotMutated() {
    const s = RadialMenu.open(500, 400, opts);
    RadialMenu.move(s, 500, 520, tree, opts);
    RadialMenu.move(s, 500, 560, tree, opts);
    compare(s.path.length, 0);
    compare(s.hovered, -1);
    verify(!s.dragged);
  }

  // --- tree editing

  function test_addRemoveMoveUpdate() {
    let t = RadialMenu.addItem(tree, [], {
                                 "action": "command",
                                 "arg": "foot"
                               });
    compare(t.length, 5);
    compare(tree.length, 4);
    t = RadialMenu.addItem(t, [2], {
                             "action": "lock"
                           });
    compare(t[2].children.length, 3);
    t = RadialMenu.moveItem(t, [], 4, -4);
    compare(t[0].action, "command");
    t = RadialMenu.moveItem(t, [], 0, -1);
    compare(t[0].action, "command");
    t = RadialMenu.removeItem(t, [3], 0);
    compare(t[3].children.length, 2);
    compare(t[3].children[0].arg, "firefox");
    t = RadialMenu.updateItem(t, [], 0, {
                                "action": "folder"
                              });
    compare(t[0].children.length, 0);
    t = RadialMenu.updateItem(t, [], 0, {
                                "action": "lock"
                              });
    verify(t[0].children === undefined);
  }

  function test_addRespectsRingLimit() {
    let t = [];
    for (let i = 0; i < 15; i++)
      t = RadialMenu.addItem(t, [], {
                               "action": "lock"
                             });
    compare(t.length, RadialMenu.maxItemsPerRing);
  }

  function test_flatten() {
    const rows = RadialMenu.flatten(tree);
    compare(rows.length, 6);
    compare(rows[3].depth, 1);
    compare(rows[3].path, [2]);
    compare(rows[3].index, 0);
    compare(rows[5].item.action, "lock");
    compare(rows[5].count, 4);
  }

  // --- per-style visuals

  function test_visualFallsBackToSegment() {
    const v = RadialMenu.visual(undefined);
    compare(v.shape, "segment");
    compare(v.colors.hover, "primary");
    compare(RadialMenu.visual({
                                "shape": "unknown"
                              }).shape, "segment");
  }

  function test_visualShapePresetsDiffer() {
    const orbit = RadialMenu.visual({
                                      "shape": "orbit"
                                    });
    const chunky = RadialMenu.visual({
                                       "shape": "chunky"
                                     });
    verify(orbit.trackWidth > 0);
    compare(orbit.easing, "OutBack");
    verify(chunky.borderWidth > 0);
    verify(chunky.shadowY > 0);
    compare(chunky.colors.outline, "ink");
    compare(chunky.centerShape, "squircle");
  }

  function test_visualStyleOverridesWinAndNestedColorsMerge() {
    const v = RadialMenu.visual({
                                  "shape": "chunky",
                                  "shadowY": 3,
                                  "colors": {
                                    "hover": "tertiary"
                                  }
                                });
    compare(v.shadowY, 3);
    compare(v.colors.hover, "tertiary");
    compare(v.colors.outline, "ink");
    // Presets are not mutated
    compare(RadialMenu.visual({
                                "shape": "chunky"
                              }).colors.hover, "primary");
  }

  function test_everyUiStyleHasItsOwnLook() {
    const shapes = {};
    for (const choice of UiStyles.choices()) {
      const spec = UiStyles.tokens(choice.key).radialMenu;
      const v = RadialMenu.visual(spec);
      verify(Object.prototype.hasOwnProperty.call(RadialMenu.shapePresets, v.shape), choice.key);
      verify(v.outerRadius > v.innerRadius, choice.key);
      if (spec)
        shapes[choice.key] = v.shape;
    }
    compare(shapes["material"], "segment");
    compare(shapes["caelestia"], "orbit");
  }

  function test_colorSource_data() {
    return [
          {
            tag: "theme role",
            role: "onPrimary",
            kind: "theme",
            value: "mOnPrimary"
          },
          {
            tag: "literal",
            role: "#fff3dc",
            kind: "literal",
            value: "#fff3dc"
          },
          {
            tag: "ink",
            role: "ink",
            kind: "ink",
            value: 0.28
          },
          {
            tag: "missing falls back to primary",
            role: "",
            kind: "theme",
            value: "mPrimary"
          }
        ];
  }

  function test_colorSource(data) {
    const source = RadialMenu.colorSource(data.role);
    compare(source.kind, data.kind);
    compare(source.value, data.value);
  }

  function test_keycapLikeSpec() {
    // The block suggested for the keycap style: chunky with a cream keyline
    const v = RadialMenu.visual({
                                  "shape": "chunky",
                                  "keylineWidth": 1,
                                  "shadowY": 3,
                                  "colors": {
                                    "keyline": "#fff3dc"
                                  }
                                });
    compare(v.keylineWidth, 1);
    compare(v.colors.keyline, "#fff3dc");
    compare(v.colors.outline, "ink");
    compare(RadialMenu.visual({
                                "shape": "segment"
                              }).keylineWidth, 0);
  }

  function test_nearestAngle_data() {
    return [
          {
            tag: "plain",
            current: 0,
            target: 90,
            result: 90
          },
          {
            tag: "across zero backwards",
            current: 10,
            target: 300,
            result: -60
          },
          {
            tag: "across zero forwards",
            current: 350,
            target: 20,
            result: 380
          },
          {
            tag: "after several turns",
            current: 720,
            target: 90,
            result: 810
          }
        ];
  }

  function test_nearestAngle(data) {
    compare(RadialMenu.nearestAngle(data.current, data.target), data.result);
  }

  function test_staggerDelay() {
    compare(RadialMenu.staggerDelay(0, 5, 20), 0);
    compare(RadialMenu.staggerDelay(3, 5, 20), 60);
    compare(RadialMenu.staggerDelay(3, 5, -1), 0);
  }
}
