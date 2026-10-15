import QtQuick
import QtTest
import "../Helpers/BubbleLogic.js" as Bubbles

TestCase {
  name: "Bubbles"

  readonly property var defaults: ({
                                     position: "top",
                                     alignment: "end",
                                     style: "floating",
                                     margin: 8,
                                     spacing: 8,
                                     height: 34,
                                     padding: 4,
                                     radius: 16,
                                     backgroundColorKey: "none",
                                     oledMode: false,
                                     opacity: 0.93,
                                     autoCycle: true,
                                     cycleInterval: 5,
                                     transition: "up",
                                     transitionDuration: 220,
                                     hideOnFullscreen: true
                                   })
  readonly property list<var> savedBubbles: [
    {
      id: "saved",
      monitor: "DP-2",
      widgets: [
        {
          id: "Clock",
          formatHorizontal: "HH:mm"
        }
      ]
    }
  ]
  readonly property list<var> widgetSequence: [
    {
      id: "Clock"
    },
    {
      id: "Volume"
    }
  ]

  function bubble(id, monitor, patch) {
    return Object.assign({
                           id: id,
                           monitor: monitor,
                           widgets: [
                             {
                               id: "Clock"
                             }
                           ]
                         }, patch || {});
  }

  function test_cycleWrapsInBothDirections() {
    compare(Bubbles.nextIndex(2, 3, 1), 0);
    compare(Bubbles.nextIndex(0, 3, -1), 2);
    compare(Bubbles.nextIndex(0, 1, 1), 0);
    compare(Bubbles.nextIndex(0, 0, 1), 0);
    compare(Bubbles.nextIndex(0, 3, -7), 2);
  }

  function test_effectiveSettingsAreIndependent() {
    var config = bubble("one", "DP-1", {
                          position: "bottom",
                          autoCycle: false
                        });
    var effective = Bubbles.effective(config, defaults);
    compare(effective.position, "bottom");
    compare(effective.height, 34);
    compare(effective.hideOnFullscreen, true);
    compare(effective.autoCycle, false);
    compare(effective.oledMode, false);
    compare(defaults.position, "top");
    verify(config.height === undefined);
  }

  function test_oledModeForcesOpaqueBlackBackground() {
    var normal = Bubbles.effective({
                                     backgroundColorKey: "primary",
                                     opacity: 0.4
                                   }, defaults);
    compare(Bubbles.backgroundColor(normal, "#123456"), "#123456");
    compare(Bubbles.backgroundOpacity(normal), 0.4);

    var oled = Bubbles.effective({
                                   oledMode: true,
                                   backgroundColorKey: "primary",
                                   opacity: 0.4
                                 }, defaults);
    compare(Bubbles.backgroundColor(oled, "#123456"), "#000000");
    compare(Bubbles.backgroundOpacity(oled), 1);
    compare(Bubbles.effective({
                                oledMode: "true"
                              }, defaults).oledMode, false);
  }

  function test_bubbleWidgetsHaveNoSeparateBackground() {
    compare(Bubbles.widgetBackground("bubble:clock", "#123456"), "transparent");
    compare(Bubbles.widgetBackground("bubble:clock", "#abcdef"), "transparent");
    compare(Bubbles.widgetBackground("left", "#123456"), "#123456");
    compare(Bubbles.widgetBackground("", "#123456"), "#123456");
  }

  function test_oledContextIsInheritedOnlyInsideItsBubble() {
    var bubbleViewport = {
      bubbleContext: {
        oledMode: true
      },
      parent: null
    };
    var widget = {
      parent: bubbleViewport
    };
    var text = {
      parent: widget
    };
    verify(Bubbles.isOledItem(text));
    bubbleViewport.bubbleContext.oledMode = false;
    verify(!Bubbles.isOledItem(text));
    verify(!Bubbles.isOledItem({
                                 parent: null
                               }));
  }

  function test_savedQmlWidgetSequencesAreRendered() {
    var saved = Bubbles.effective(savedBubbles[0], defaults);
    compare(saved.widgets.length, 1);
    compare(saved.widgets[0].id, "Clock");
    compare(saved.widgets[0].formatHorizontal, "HH:mm");
    compare(Bubbles.effective({
                                widgets: widgetSequence
                              }, defaults).widgets.length, 2);
    compare(Bubbles.effective({
                                widgets: null
                              }, defaults).widgets.length, 0);
  }

  function test_invalidGeometryAndTimingAreClamped() {
    var config = Bubbles.effective({
                                     position: "bad",
                                     alignment: "bad",
                                     style: "bad",
                                     transition: "bad",
                                     height: -1,
                                     padding: -2,
                                     margin: Infinity,
                                     radius: 1000,
                                     opacity: 2,
                                     cycleInterval: 0,
                                     transitionDuration: -10
                                   }, defaults);
    compare(config.position, "top");
    compare(config.alignment, "end");
    compare(config.style, "floating");
    compare(config.transition, "up");
    compare(config.height, 20);
    compare(config.padding, 0);
    compare(config.margin, 8);
    compare(config.radius, 50);
    compare(config.opacity, 1);
    compare(config.cycleInterval, 1);
    compare(config.transitionDuration, 0);
  }

  function test_wheel_data() {
    return [
          {
            tag: "mouse down",
            accumulator: 0,
            x: 0,
            y: -120,
            pixel: false,
            step: 1,
            remaining: 0
          },
          {
            tag: "mouse up",
            accumulator: 0,
            x: 0,
            y: 120,
            pixel: false,
            step: -1,
            remaining: 0
          },
          {
            tag: "touchpad horizontal",
            accumulator: 0,
            x: -45,
            y: 10,
            pixel: true,
            step: 1,
            remaining: 0
          },
          {
            tag: "touchpad vertical",
            accumulator: 0,
            x: 5,
            y: 40,
            pixel: true,
            step: -1,
            remaining: 0
          },
          {
            tag: "small touchpad movement",
            accumulator: 0,
            x: -10,
            y: 0,
            pixel: true,
            step: 0,
            remaining: -10
          },
          {
            tag: "accumulated touchpad movement",
            accumulator: -30,
            x: -10,
            y: 0,
            pixel: true,
            step: 1,
            remaining: 0
          },
          {
            tag: "reversing starts fresh",
            accumulator: -30,
            x: 20,
            y: 0,
            pixel: true,
            step: 0,
            remaining: 20
          },
          {
            tag: "zero delta",
            accumulator: 12,
            x: 0,
            y: 0,
            pixel: false,
            step: 0,
            remaining: 12
          },
          {
            tag: "fast wheel makes one step",
            accumulator: 0,
            x: 0,
            y: -960,
            pixel: false,
            step: 1,
            remaining: 0
          }
        ];
  }

  function test_wheel(data) {
    var result = Bubbles.wheelStep(data.accumulator, data.x, data.y, data.pixel);
    compare(result.step, data.step);
    compare(result.accumulator, data.remaining);
  }

  function test_animationDirection_data() {
    return [
          {
            tag: "up",
            direction: "up",
            x: 0,
            y: -1
          },
          {
            tag: "down",
            direction: "down",
            x: 0,
            y: 1
          },
          {
            tag: "left",
            direction: "left",
            x: -1,
            y: 0
          },
          {
            tag: "right",
            direction: "right",
            x: 1,
            y: 0
          },
          {
            tag: "fade",
            direction: "fade",
            x: 0,
            y: 0
          }
        ];
  }

  function test_animationDirection(data) {
    compare(Bubbles.animationVector(data.direction, 1), {
              x: data.x,
              y: data.y
            });
    compare(Bubbles.animationVector(data.direction, -1), {
              x: -data.x,
              y: -data.y
            });
  }

  function test_visibility() {
    verify(Bubbles.shouldShow(true, 1, true, false));
    verify(!Bubbles.shouldShow(true, 1, true, true));
    verify(Bubbles.shouldShow(true, 1, false, true));
    verify(!Bubbles.shouldShow(false, 1, false, false));
    verify(!Bubbles.shouldShow(true, 0, false, false));
  }

  function test_autoCyclePausesDuringInteractionAndRespectsManualMode() {
    verify(Bubbles.shouldAutoCycle(true, true, 2, false, false));
    verify(!Bubbles.shouldAutoCycle(true, false, 2, false, false));
    verify(!Bubbles.shouldAutoCycle(true, true, 1, false, false));
    verify(!Bubbles.shouldAutoCycle(false, true, 2, false, false));
    verify(!Bubbles.shouldAutoCycle(true, true, 2, true, false));
    verify(!Bubbles.shouldAutoCycle(true, true, 2, false, true));
  }

  function test_fullscreenIsPerMonitorAndIgnoresMinimizedWindows() {
    var windows = [
          {
            fullscreen: true,
            screens: [
              {
                name: "DP-1"
              }
            ]
          },
          {
            fullscreen: false,
            screens: [
              {
                name: "DP-2"
              }
            ]
          }
        ];
    verify(Bubbles.hasFullscreen(windows, "DP-1"));
    verify(!Bubbles.hasFullscreen(windows, "DP-2"));
    windows[0].minimized = true;
    verify(!Bubbles.hasFullscreen(windows, "DP-1"));
    verify(!Bubbles.hasFullscreen([], "DP-1"));
  }

  function test_monitorSelectionAndPanelAvailability() {
    var configs = [bubble("a", "DP-1"), bubble("b", "DP-2"), bubble("c", "DP-1")];
    compare(Bubbles.forMonitor(configs, "DP-1").length, 2);
    compare(Bubbles.find(configs, "DP-2", "b").monitor, "DP-2");
    compare(Bubbles.find(configs, "DP-1", "b"), null);
    verify(Bubbles.wantsPanels(true, configs, "DP-2"));
    verify(!Bubbles.wantsPanels(false, configs, "DP-2"));
    verify(!Bubbles.wantsPanels(true, [bubble("a", "DP-1", {
                                                widgets: []
                                              })], "DP-1"));
  }

  function test_widgetSettingsDoNotLeakBetweenBubblesOrMonitors() {
    var configs = [bubble("a", "DP-1"), bubble("b", "DP-1"), bubble("a", "DP-2")];
    var updated = Bubbles.updateWidget(configs, "DP-1", "a", 0, {
                                         formatHorizontal: "HH:mm"
                                       });
    compare(updated[0].widgets[0].id, "Clock");
    compare(updated[0].widgets[0].formatHorizontal, "HH:mm");
    verify(updated[1].widgets[0].formatHorizontal === undefined);
    verify(updated[2].widgets[0].formatHorizontal === undefined);
    verify(configs[0].widgets[0].formatHorizontal === undefined);
    compare(Bubbles.updateWidget(configs, "DP-1", "a", 3, {}), configs);
  }

  function test_reorderDoesNotMutateOriginal() {
    var widgets = [
          {
            id: "Clock"
          },
          {
            id: "Volume"
          },
          {
            id: "Battery"
          }
        ];
    compare(Bubbles.reorder(widgets, 0, 2).map(function (w) {
      return w.id;
    }), ["Volume", "Battery", "Clock"]);
    compare(widgets[0].id, "Clock");
    compare(Bubbles.reorder(widgets, -1, 2), widgets);
  }

  function test_backgroundColor_data() {
    return [
          {
            tag: "legacy config",
            key: undefined,
            expected: "none"
          },
          {
            tag: "surface",
            key: "none",
            expected: "none"
          },
          {
            tag: "primary",
            key: "primary",
            expected: "primary"
          },
          {
            tag: "secondary",
            key: "secondary",
            expected: "secondary"
          },
          {
            tag: "tertiary",
            key: "tertiary",
            expected: "tertiary"
          },
          {
            tag: "error",
            key: "error",
            expected: "error"
          },
          {
            tag: "outline",
            key: "outline",
            expected: "outline"
          },
          {
            tag: "unknown key",
            key: "invalid",
            expected: "none"
          },
          {
            tag: "null key",
            key: null,
            expected: "none"
          }
        ];
  }

  function test_backgroundColor(data) {
    var config = data.key === undefined ? {} : {
      backgroundColorKey: data.key
    };
    compare(Bubbles.effective(config, defaults).backgroundColorKey, data.expected);
  }

  function test_moveBubblePreservesOtherMonitorsAndWidgetSettings() {
    var configs = [bubble("a", "DP-1"), bubble("other", "DP-2"), bubble("b", "DP-1", {
                                                                          backgroundColorKey: "primary"
                                                                        })];
    var moved = Bubbles.moveBubble(configs, "DP-1", "b", -1);
    compare(moved.map(function (b) {
      return b.id;
    }), ["b", "other", "a"]);
    compare(moved[0].backgroundColorKey, "primary");
    compare(moved[0].widgets, configs[2].widgets);
    compare(moved[1], configs[1]);
    compare(configs[0].id, "a");
    compare(Bubbles.moveBubble(moved, "DP-1", "b", 1), configs);
    compare(Bubbles.moveBubble(configs, "DP-1", "a", -1), configs);
    compare(Bubbles.moveBubble(configs, "DP-1", "b", 1), configs);
    compare(Bubbles.moveBubble(configs, "DP-2", "b", -1), configs);
    compare(Bubbles.moveBubble(null, "DP-1", "a", 1), []);
    compare(Bubbles.moveBubble(savedBubbles, "DP-2", "saved", -1).length, 1);
  }

  function test_searchRevealsOnlyMatchingBubbleSettings() {
    var widgets = {
      label: "Widgets",
      children: []
    };
    var firstSettings = {
      expanded: false,
      children: [
        {
          label: "Background color"
        }
      ]
    };
    var secondSettings = {
      expanded: false,
      children: [
        {
          label: "Background color"
        }
      ]
    };
    var tab = {
      children: [widgets, firstSettings, secondSettings]
    };
    verify(!Bubbles.revealSetting(tab, "Widgets"));
    verify(!firstSettings.expanded);
    verify(Bubbles.revealSetting(tab, "Background color"));
    verify(firstSettings.expanded);
    verify(!secondSettings.expanded);
    verify(!Bubbles.revealSetting(tab, "Background color"));
    verify(!Bubbles.revealSetting(tab, "missing"));
    verify(!Bubbles.revealSetting(null, "Background color"));
  }

  function test_searchRevealsNestedCollapsedSections() {
    var inner = {
      expanded: false,
      children: [
        {
          label: "Position"
        }
      ]
    };
    var outer = {
      expanded: false,
      children: [inner]
    };
    verify(Bubbles.revealSetting(outer, "Position"));
    verify(outer.expanded);
    verify(inner.expanded);
  }

  function test_layoutEdges_data() {
    return [
          {
            tag: "floating top",
            position: "top",
            style: "floating",
            x: 400,
            y: 8
          },
          {
            tag: "floating bottom",
            position: "bottom",
            style: "floating",
            x: 400,
            y: 642
          },
          {
            tag: "floating left",
            position: "left",
            style: "floating",
            x: 8,
            y: 325
          },
          {
            tag: "floating right",
            position: "right",
            style: "floating",
            x: 792,
            y: 325
          },
          {
            tag: "attached top",
            position: "top",
            style: "attached",
            x: 400,
            y: 0
          },
          {
            tag: "notch bottom",
            position: "bottom",
            style: "notch",
            x: 400,
            y: 650
          }
        ];
  }

  function test_layoutEdges(data) {
    var configs = [bubble("a", "DP-1", {
                            position: data.position,
                            style: data.style,
                            alignment: "center"
                          })];
    compare(Bubbles.layout(configs, defaults, {
                             "DP-1|a": {
                               width: 200,
                               height: 50
                             }
                           }, "DP-1", "a", 1000, 700), {
              x: data.x,
              y: data.y,
              width: 200,
              height: 50
            });
  }

  function test_groupCentersAndDoesNotOverlap() {
    var configs = [bubble("a", "DP-1", {
                            alignment: "center"
                          }), bubble("b", "DP-1", {
                                       alignment: "center"
                                     }), bubble("c", "DP-2")];
    var sizes = {
      "DP-1|a": {
        width: 100,
        height: 34
      },
      "DP-1|b": {
        width: 200,
        height: 34
      }
    };
    var first = Bubbles.layout(configs, defaults, sizes, "DP-1", "a", 1000, 700);
    var second = Bubbles.layout(configs, defaults, sizes, "DP-1", "b", 1000, 700);
    compare(first.x, 346);
    compare(second.x, 454);
    compare(second.x - first.x - first.width, 8);
    configs[0].alignment = "end";
    configs[1].alignment = "end";
    compare(Bubbles.layout(configs, defaults, sizes, "DP-1", "b", 1000, 700).x, 792);
  }

  function test_mixedStylesHaveSymmetricBodySpacing_data() {
    var rows = [];
    ["top", "bottom", "left", "right"].forEach(function (position) {
      ["start", "center", "end"].forEach(function (alignment) {
        [false, true].forEach(function (reverse) {
          rows.push({
                      tag: position + " " + alignment + " " + reverse,
                      position: position,
                      alignment: alignment,
                      reverse: reverse
                    });
        });
      });
    });
    return rows;
  }

  function test_mixedStylesHaveSymmetricBodySpacing(data) {
    var notch = bubble("notch", "DP-1", {
                         position: data.position,
                         alignment: data.alignment,
                         style: "notch"
                       });
    var floating = bubble("floating", "DP-1", {
                            position: data.position,
                            alignment: data.alignment,
                            height: 30
                          });
    var configs = data.reverse ? [floating, notch] : [notch, floating];
    var vertical = Bubbles.isVertical(data.position);
    var sizes = {
      "DP-1|notch": vertical ? {
                                 width: 34,
                                 height: 105
                               } : {
        width: 105,
        height: 34
      },
      "DP-1|floating": vertical ? {
                                    width: 30,
                                    height: 38
                                  } : {
        width: 38,
        height: 30
      }
    };
    var first = Bubbles.layout(configs, defaults, sizes, "DP-1", configs[0].id, 1000, 700);
    var second = Bubbles.layout(configs, defaults, sizes, "DP-1", configs[1].id, 1000, 700);
    var firstBody = Bubbles.bodyRect(Bubbles.effective(configs[0], defaults), first.width, first.height);
    var secondBody = Bubbles.bodyRect(Bubbles.effective(configs[1], defaults), second.width, second.height);
    if (vertical) {
      compare(first.x + first.width / 2, second.x + second.width / 2);
      compare(second.y + secondBody.y - first.y - firstBody.y - firstBody.height, 8);
    } else {
      compare(first.y + first.height / 2, second.y + second.height / 2);
      compare(second.x + secondBody.x - first.x - firstBody.x - firstBody.width, 8);
    }
    var floatPlacement = data.reverse ? first : second;
    var notchPlacement = data.reverse ? second : first;
    compare(vertical ? notchPlacement.width : notchPlacement.height, 46);
    switch (data.position) {
    case "top":
      compare(floatPlacement.y, 8);
      compare(notchPlacement.y, 0);
      break;
    case "bottom":
      compare(floatPlacement.y + floatPlacement.height, 692);
      compare(notchPlacement.y + notchPlacement.height, 700);
      break;
    case "left":
      compare(floatPlacement.x, 8);
      compare(notchPlacement.x, 0);
      break;
    case "right":
      compare(floatPlacement.x + floatPlacement.width, 992);
      compare(notchPlacement.x + notchPlacement.width, 1000);
      break;
    }
    compare(sizes["DP-1|notch"], vertical ? {
                                              width: 34,
                                              height: 105
                                            } : {
              width: 105,
              height: 34
            });
  }

  function test_adjacentNotchesKeepFlareSpacing() {
    var configs = [bubble("a", "DP-1", {
                            style: "notch"
                          }), bubble("b", "DP-1", {
                                       style: "notch"
                                     })];
    var sizes = {
      "DP-1|a": {
        width: 100,
        height: 34
      },
      "DP-1|b": {
        width: 100,
        height: 34
      }
    };
    var first = Bubbles.layout(configs, defaults, sizes, "DP-1", "a", 1000, 700);
    var second = Bubbles.layout(configs, defaults, sizes, "DP-1", "b", 1000, 700);
    compare(second.x - first.x - first.width, 8);
    compare(first.height, 34);
    compare(second.height, 34);
  }

  function test_attachedAndFloatingUseSharedGroupOrigin() {
    var configs = [bubble("a", "DP-1", {
                            style: "attached",
                            alignment: "start"
                          }), bubble("b", "DP-1", {
                                       alignment: "start"
                                     })];
    var sizes = {
      "DP-1|a": {
        width: 100,
        height: 34
      },
      "DP-1|b": {
        width: 50,
        height: 34
      }
    };
    var first = Bubbles.layout(configs, defaults, sizes, "DP-1", "a", 1000, 700);
    var second = Bubbles.layout(configs, defaults, sizes, "DP-1", "b", 1000, 700);
    compare(first.x, 0);
    compare(second.x - first.x - first.width, 8);
    compare(first.y + first.height / 2, second.y + second.height / 2);
    configs.reverse();
    configs.forEach(function (config) {
      config.alignment = "end";
    });
    first = Bubbles.layout(configs, defaults, sizes, "DP-1", "b", 1000, 700);
    second = Bubbles.layout(configs, defaults, sizes, "DP-1", "a", 1000, 700);
    compare(second.x + second.width, 1000);
    compare(second.x - first.x - first.width, 8);
  }

  function test_notchInputBodyExcludesOverlappingFlareBounds() {
    var notch = Bubbles.effective({
                                    style: "notch",
                                    radius: 50
                                  }, defaults);
    compare(Bubbles.notchFlare(notch), 17);
    compare(Bubbles.bodyRect(notch, 120, 50), {
              x: 17,
              y: 0,
              width: 86,
              height: 50
            });
    notch.position = "right";
    compare(Bubbles.bodyRect(notch, 50, 120), {
              x: 0,
              y: 17,
              width: 50,
              height: 86
            });
    compare(Bubbles.bodyRect(notch, 1, 1), {
              x: 0,
              y: 0.25,
              width: 1,
              height: 0.5
            });
    notch.style = "floating";
    compare(Bubbles.bodyRect(notch, 50, 120), {
              x: 0,
              y: 0,
              width: 50,
              height: 120
            });
  }

  function test_attachedCorners_data() {
    return [
          {
            tag: "top left",
            position: "top",
            alignment: "start",
            x: 0,
            y: 0
          },
          {
            tag: "top right",
            position: "top",
            alignment: "end",
            x: 800,
            y: 0
          },
          {
            tag: "bottom left",
            position: "bottom",
            alignment: "start",
            x: 0,
            y: 650
          },
          {
            tag: "bottom right",
            position: "bottom",
            alignment: "end",
            x: 800,
            y: 650
          },
          {
            tag: "left top",
            position: "left",
            alignment: "start",
            x: 0,
            y: 0
          },
          {
            tag: "left bottom",
            position: "left",
            alignment: "end",
            x: 0,
            y: 650
          },
          {
            tag: "right top",
            position: "right",
            alignment: "start",
            x: 800,
            y: 0
          },
          {
            tag: "right bottom",
            position: "right",
            alignment: "end",
            x: 800,
            y: 650
          }
        ];
  }

  function test_attachedCorners(data) {
    var configs = [bubble("a", "DP-1", {
                            style: "attached",
                            position: data.position,
                            alignment: data.alignment,
                            margin: 30
                          })];
    compare(Bubbles.layout(configs, defaults, {
                             "DP-1|a": {
                               width: 200,
                               height: 50
                             }
                           }, "DP-1", "a", 1000, 700), {
              x: data.x,
              y: data.y,
              width: 200,
              height: 50
            });
  }

  function test_notchesAndFloatingKeepTheirEndMargin() {
    var sizes = {
      "DP-1|a": {
        width: 200,
        height: 50
      }
    };
    var configs = [bubble("a", "DP-1", {
                            style: "notch",
                            alignment: "end",
                            margin: 30
                          })];
    var notch = Bubbles.layout(configs, defaults, sizes, "DP-1", "a", 1000, 700);
    compare(notch.x, 770);
    compare(notch.y, 0);
    configs[0].alignment = "start";
    compare(Bubbles.layout(configs, defaults, sizes, "DP-1", "a", 1000, 700).x, 30);
    configs[0].style = "floating";
    configs[0].alignment = "end";
    var floating = Bubbles.layout(configs, defaults, sizes, "DP-1", "a", 1000, 700);
    compare(floating.x, 770);
    compare(floating.y, 30);
  }

  function test_layoutClampsOffsetsAndOversizedWidgets() {
    var configs = [bubble("a", "DP-1", {
                            offset: 99999
                          })];
    var result = Bubbles.layout(configs, defaults, {
                                  "DP-1|a": {
                                    width: 1200,
                                    height: 40
                                  }
                                }, "DP-1", "a", 1000, 700);
    compare(result.x, 0);
    compare(result.width, 1000);
    configs[0].offset = -99999;
    compare(Bubbles.layout(configs, defaults, {}, "DP-1", "a", 1000, 700).x, 0);
  }

  function test_emptyBubblesDoNotTakeGroupSpace() {
    var configs = [bubble("empty", "DP-1", {
                            widgets: []
                          }), bubble("a", "DP-1")];
    compare(Bubbles.layout(configs, defaults, {
                             "DP-1|a": {
                               width: 100,
                               height: 34
                             }
                           }, "DP-1", "a", 1000, 700).x, 892);
  }

  function test_inactiveWidgetsKeepMeasurementsWhileHiddenBarWidgetsCollapse() {
    var clock = {
      visible: true,
      implicitWidth: 90,
      implicitHeight: 30
    };
    var volume = {
      visible: false,
      implicitWidth: 40,
      implicitHeight: 30
    };
    compare(Bubbles.widgetExtent(clock, "implicitWidth", true), 90);
    compare(Bubbles.widgetExtent(volume, "implicitWidth", true), 40);
    clock.visible = false;
    volume.visible = true;
    compare(Bubbles.widgetExtent(clock, "implicitWidth", true), 90);
    compare(Bubbles.widgetExtent(volume, "implicitWidth", true), 40);
    compare(Bubbles.widgetExtent(clock, "implicitWidth", false), 0);
    compare(Bubbles.widgetExtent(null, "implicitWidth", true), 0);
  }

  function test_contentSizeStylesAndOrientation_data() {
    return [
          {
            tag: "floating top",
            position: "top",
            style: "floating",
            width: 208,
            height: 60
          },
          {
            tag: "attached bottom",
            position: "bottom",
            style: "attached",
            width: 208,
            height: 60
          },
          {
            tag: "notched top",
            position: "top",
            style: "notch",
            width: 240,
            height: 60
          },
          {
            tag: "floating left",
            position: "left",
            style: "floating",
            width: 200,
            height: 68
          },
          {
            tag: "attached right",
            position: "right",
            style: "attached",
            width: 200,
            height: 68
          },
          {
            tag: "notched right",
            position: "right",
            style: "notch",
            width: 200,
            height: 100
          }
        ];
  }

  function test_contentSizeStylesAndOrientation(data) {
    var config = Bubbles.effective({
                                     position: data.position,
                                     style: data.style
                                   }, defaults);
    compare(Bubbles.contentSize({
                                  implicitWidth: 200,
                                  implicitHeight: 60
                                }, config), {
              width: data.width,
              height: data.height
            });
  }

  function test_contentSizeShrinksAndGrowsWithCurrentWidget() {
    var config = Bubbles.effective({
                                     height: 30
                                   }, defaults);
    var icon = {
      visible: true,
      implicitWidth: 30,
      implicitHeight: 30
    };
    var visualizer = {
      visible: false,
      implicitWidth: 200,
      implicitHeight: 30
    };
    compare(Bubbles.contentSize(icon, config), {
              width: 38,
              height: 30
            });
    icon.visible = false;
    visualizer.visible = true;
    compare(Bubbles.contentSize(visualizer, config), {
              width: 208,
              height: 30
            });
    icon.visible = true;
    visualizer.visible = false;
    compare(Bubbles.contentSize(icon, config), {
              width: 38,
              height: 30
            });
    icon.implicitWidth = 85;
    compare(Bubbles.contentSize(icon, config), {
              width: 93,
              height: 30
            });
    icon.implicitWidth = 30;
    compare(Bubbles.contentSize(icon, config), {
              width: 38,
              height: 30
            });
    compare(Bubbles.contentSize(null, config), {
              width: 38,
              height: 30
            });
    compare(config.height, 30);
  }

  function test_resizingCurrentWidgetReflowsAdjacentBubbles() {
    var configs = [bubble("a", "DP-1"), bubble("b", "DP-1")];
    var sizes = {
      "DP-1|a": {
        width: 208,
        height: 34
      },
      "DP-1|b": {
        width: 90,
        height: 34
      }
    };
    var before = Bubbles.layout(configs, defaults, sizes, "DP-1", "a", 1000, 700);
    sizes["DP-1|a"] = {
      width: 38,
      height: 34
    };
    var after = Bubbles.layout(configs, defaults, sizes, "DP-1", "a", 1000, 700);
    var next = Bubbles.layout(configs, defaults, sizes, "DP-1", "b", 1000, 700);
    compare(after.x - before.x, 170);
    compare(after.width, 38);
    compare(next.x - after.x - after.width, defaults.spacing);
    compare(next.x + next.width, 1000 - defaults.margin);
  }

  function test_backgroundStylesAndEdges() {
    var notch = Bubbles.backgroundPath(120, 40, 12, "notch", "top");
    verify(notch.indexOf("M 0 0 L 120 0 Q 108 0 108 12") === 0);
    verify(Bubbles.backgroundPath(120, 40, 12, "attached", "top").indexOf("M 0 0") === 0);
    verify(Bubbles.backgroundPath(120, 40, 12, "floating", "top").indexOf("M 12 0") === 0);
    verify(Bubbles.backgroundPath(120, 40, 12, "notch", "bottom").indexOf("M 0 40 L 120 40") === 0);
    verify(Bubbles.backgroundPath(40, 120, 12, "notch", "left").indexOf("M 0 0 L 0 120") === 0);
    verify(Bubbles.backgroundPath(40, 120, 12, "notch", "right").indexOf("M 40 0 L 40 120") === 0);
    verify(Bubbles.backgroundPath(20, 20, 100, "notch", "top").indexOf("NaN") < 0);
    compare(Bubbles.backgroundPath(120, 40, 0, "notch", "top"), "M 0 0 L 120 0 L 120 40 L 0 40 Z");
  }

  function test_attachedCornerFillsBothScreenEdges() {
    var topRight = Bubbles.backgroundPath(120, 40, 12, "attached", "top", "end");
    compare(topRight, "M 0 0 L 120 0 L 120 40 L 12 40 Q 0 40 0 28 L 0 0 Z");
    var topLeft = Bubbles.backgroundPath(120, 40, 12, "attached", "top", "start");
    compare(topLeft, "M 0 0 L 120 0 L 120 28 Q 120 40 108 40 L 0 40 L 0 0 Z");
    var bottomRight = Bubbles.backgroundPath(120, 40, 12, "attached", "bottom", "end");
    compare(bottomRight, "M 0 40 L 120 40 L 120 0 L 12 0 Q 0 0 0 12 L 0 40 Z");
    var rightBottom = Bubbles.backgroundPath(40, 120, 12, "attached", "right", "end");
    compare(rightBottom, "M 40 0 L 40 120 L 0 120 L 0 12 Q 0 0 12 0 L 40 0 Z");
    compare(Bubbles.backgroundPath(120, 40, 12, "notch", "top", "end"), Bubbles.backgroundPath(120, 40, 12, "notch", "top"));
  }

  function test_onlyBubbleTouchingCornerLosesSideRounding() {
    compare(Bubbles.cornerAttachment({
                                       x: 800,
                                       y: 0,
                                       width: 200,
                                       height: 50
                                     }, "top", 1000, 700), "end");
    compare(Bubbles.cornerAttachment({
                                       x: 0,
                                       y: 0,
                                       width: 200,
                                       height: 50
                                     }, "top", 1000, 700), "start");
    compare(Bubbles.cornerAttachment({
                                       x: 700,
                                       y: 0,
                                       width: 200,
                                       height: 50
                                     }, "top", 1000, 700), "");
    compare(Bubbles.cornerAttachment({
                                       x: 0,
                                       y: 650,
                                       width: 50,
                                       height: 50
                                     }, "left", 1000, 700), "end");
    compare(Bubbles.cornerAttachment({
                                       x: 0,
                                       y: 0,
                                       width: 1000,
                                       height: 50
                                     }, "top", 1000, 700), "both");
  }

  function test_contextFoundThroughNestedWidgetItems() {
    var context = {
      section: "bubble:a",
      position: "bottom",
      x: 300,
      y: 600
    };
    compare(Bubbles.itemContext({
                                  parent: {
                                    parent: {
                                      bubbleContext: context
                                    }
                                  }
                                }), context);
    compare(Bubbles.itemContext({
                                  parent: null
                                }), null);
    verify(Bubbles.isBubbleSection(context.section));
    verify(!Bubbles.isBubbleSection("left"));
  }

  function test_panelsOpenBesideBubbleAndStayOnScreen() {
    var button = {
      x: 400,
      y: 660,
      width: 100,
      height: 32
    };
    compare(Bubbles.panelPosition(button, "bottom", 300, 200, 1000, 700, 8), {
              x: 300,
              y: 452
            });
    button = {
      x: 900,
      y: 8,
      width: 92,
      height: 34
    };
    compare(Bubbles.panelPosition(button, "top", 300, 200, 1000, 700, 8), {
              x: 692,
              y: 50
            });
    button = {
      x: 0,
      y: 200,
      width: 34,
      height: 34
    };
    compare(Bubbles.panelPosition(button, "left", 300, 200, 1000, 700, 8).x, 42);
  }
}
