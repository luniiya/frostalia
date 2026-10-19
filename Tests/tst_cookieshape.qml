import QtQuick
import QtTest
import "../Helpers/CookieShape.js" as CookieShape

TestCase {
  name: "CookieShape"

  function distance(point, cx, cy) {
    return Math.sqrt(Math.pow(point.x - cx, 2) + Math.pow(point.y - cy, 2));
  }

  function test_closedOutline() {
    const points = CookieShape.points(50, 50, 40, 9, 0.1, 90);
    compare(points.length, 91);
    fuzzyCompare(points[0].x, points[90].x, 0.001);
    fuzzyCompare(points[0].y, points[90].y, 0.001);
  }

  function test_lobeStartsAtTop() {
    const points = CookieShape.points(50, 50, 40, 9, 0.1, 90);
    fuzzyCompare(points[0].x, 50, 0.001);
    fuzzyCompare(points[0].y, 10, 0.001);
  }

  function test_radiusStaysInsideBounds() {
    const points = CookieShape.points(0, 0, 40, 7, 0.2, 140);
    for (let i = 0; i < points.length; i++) {
      const r = distance(points[i], 0, 0);
      verify(r <= 40.001 && r >= 31.999, "radius " + r);
    }
  }

  function test_zeroDepthIsCircle() {
    const points = CookieShape.points(10, 10, 5, 9, 0, 32);
    for (let i = 0; i < points.length; i++)
      fuzzyCompare(distance(points[i], 10, 10), 5, 0.001);
  }
}
