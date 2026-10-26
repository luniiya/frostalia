import QtQuick
import QtTest
import "../Helpers/DesktopMetrics.js" as DesktopMetrics
import "../Helpers/UiStyles.js" as UiStyles

TestCase {
  name: "DesktopMetrics"

  function test_clockFootprint_isAGridMultiple() {
    // 6 cells of the 25px grid, so a clock and the 25px gap beside it fill the grid exactly
    compare(DesktopMetrics.clockFootprint(1), 150);
  }

  function test_clockFootprint_followsWidgetScale() {
    verify(DesktopMetrics.clockFootprint(2) > DesktopMetrics.clockFootprint(1));
    verify(DesktopMetrics.clockFootprint(0.5) < DesktopMetrics.clockFootprint(1));
  }

  function test_everyTokenSizeIsDefinedAndOrdered() {
    var order = ["XXS", "XS", "S", "M", "L", "XL", "XXL", "XXXL"];
    for (var i = 1; i < order.length; i++)
      verify(DesktopMetrics.fontSizes[order[i]] >= DesktopMetrics.fontSizes[order[i - 1]], order[i]);
    var marginOrder = ["XXXS", "XXS", "XS", "S", "M", "L", "XL"];
    for (var j = 1; j < marginOrder.length; j++)
      verify(DesktopMetrics.margins[marginOrder[j]] > DesktopMetrics.margins[marginOrder[j - 1]], marginOrder[j]);
  }

  function test_metricsDoNotFollowTheUiStyle() {
    // The styles disagree on these numbers (that was the bug), the desktop metrics must not
    var material = UiStyles.tokens("material");
    var caelestia = UiStyles.tokens("caelestia");
    verify(material.fontSizes.XXXL !== caelestia.fontSizes.XXXL || material.margins.XL !== caelestia.margins.XL);
    compare(DesktopMetrics.fontSizes.XXXL, 24);
    compare(DesktopMetrics.margins.XL, 18);
  }
}
