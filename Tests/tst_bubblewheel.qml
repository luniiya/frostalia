import QtQuick
import QtTest
import "../Modules/Bubbles"

TestCase {
  id: testCase
  name: "BubbleWheel"
  width: 120
  height: 120
  visible: true
  when: windowShown

  property int widgetWheelEvents: 0
  property int widgetClicks: 0
  property int cycleSteps: 0
  // Exercise the same typed model assignment used by NSearchableComboBox.
  property ListModel pickerModel: choices

  BubbleWidgetChoices {
    id: choices
  }

  Item {
    id: surface
    anchors.fill: parent

    MouseArea {
      anchors.fill: parent
      onWheel: event => {
        testCase.widgetWheelEvents++;
        event.accepted = true;
      }
      onClicked: testCase.widgetClicks++
    }

    BubbleWheelHandler {
      id: handler
      onCycleRequested: step => testCase.cycleSteps += step
    }
  }

  function init() {
    widgetWheelEvents = 0;
    widgetClicks = 0;
    cycleSteps = 0;
    handler.widgetCount = 2;
    handler.accumulator = 0;
  }

  function test_singleWidgetKeepsItsWheelAction() {
    handler.widgetCount = 1;
    mouseWheel(surface, 60, 60, 0, -120);
    compare(widgetWheelEvents, 1);
    compare(cycleSteps, 0);
  }

  function test_multipleWidgetsConsumeWheel() {
    mouseWheel(surface, 60, 60, 0, -120);
    compare(widgetWheelEvents, 0);
    compare(cycleSteps, 1);
    mouseWheel(surface, 60, 60, 0, 120);
    compare(cycleSteps, 0);
    compare(widgetWheelEvents, 0);
  }

  function test_horizontalWheelCycles() {
    mouseWheel(surface, 60, 60, -120, 0);
    compare(cycleSteps, 1);
    compare(widgetWheelEvents, 0);
  }

  function test_smallEventsAreConsumedUntilAStep() {
    mouseWheel(surface, 60, 60, 0, -30);
    compare(cycleSteps, 0);
    compare(widgetWheelEvents, 0);
    mouseWheel(surface, 60, 60, 0, -90);
    compare(cycleSteps, 1);
  }

  function test_clicksStillReachWidget() {
    mouseClick(surface, 60, 60);
    compare(widgetClicks, 1);
  }

  function test_pickerUsesATypedModelAndUpdatesForPlugins() {
    choices.widgetIds = ["Clock", "Volume"];
    compare(pickerModel.count, 2);
    compare(pickerModel.get(0).key, "Clock");
    choices.widgetIds = ["Clock", "Volume", "plugin:timer"];
    compare(pickerModel.count, 3);
    compare(pickerModel.get(2).name, "plugin:timer");
  }
}
