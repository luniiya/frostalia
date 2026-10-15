import QtQuick
import QtTest
import "../Modules/Panels/Launcher/Helpers/LauncherNavigation.js" as Nav

TestCase {
  name: "LauncherNavigation"

  // ----- list navigation -----

  function test_selectNext() {
    compare(Nav.selectNext(0, 5), 1);
    compare(Nav.selectNext(4, 5), 4); // stays on last
    compare(Nav.selectNext(0, 0), 0); // empty list
  }

  function test_selectPrevious() {
    compare(Nav.selectPrevious(3, 5), 2);
    compare(Nav.selectPrevious(0, 5), 0); // stays on first
    compare(Nav.selectPrevious(2, 0), 2); // empty list
  }

  function test_selectNextWrapped() {
    compare(Nav.selectNextWrapped(4, 5, true), 0);
    compare(Nav.selectNextWrapped(2, 5, true), 3);
    compare(Nav.selectNextWrapped(4, 5, false), 4);
    compare(Nav.selectNextWrapped(1, 0, true), 1);
  }

  function test_selectPreviousWrapped() {
    compare(Nav.selectPreviousWrapped(0, 5, true), 4);
    compare(Nav.selectPreviousWrapped(3, 5, true), 2);
    compare(Nav.selectPreviousWrapped(0, 5, false), 0);
    compare(Nav.selectPreviousWrapped(1, 0, true), 1);
  }

  function test_selectFirstLast() {
    compare(Nav.selectFirst(), 0);
    compare(Nav.selectLast(5), 4);
    compare(Nav.selectLast(0), 0);
  }

  function test_selectNextPage() {
    // 600 / 60 = 10 entries per page
    compare(Nav.selectNextPage(0, 50, 60), 10);
    compare(Nav.selectNextPage(45, 50, 60), 49); // clamps to last
    compare(Nav.selectNextPage(0, 50, 1000), 1); // page is at least one entry
    compare(Nav.selectNextPage(3, 0, 60), 3);
  }

  function test_selectPreviousPage() {
    compare(Nav.selectPreviousPage(25, 50, 60), 15);
    compare(Nav.selectPreviousPage(4, 50, 60), 0); // clamps to first
    compare(Nav.selectPreviousPage(3, 0, 60), 3);
  }

  // ----- grid navigation (7 items, 3 columns) -----
  //  0 1 2
  //  3 4 5
  //  6

  function test_selectNextRow() {
    compare(Nav.selectNextRow(0, 7, 3), 3);
    compare(Nav.selectNextRow(3, 7, 3), 6);
    compare(Nav.selectNextRow(4, 7, 3), 6); // short last row: last item
    compare(Nav.selectNextRow(6, 7, 3), 0); // wraps to first row, same column
    compare(Nav.selectNextRow(1, 0, 3), 1);
    compare(Nav.selectNextRow(1, 7, 0), 1);
  }

  function test_selectPreviousRow() {
    compare(Nav.selectPreviousRow(4, 7, 3), 1);
    compare(Nav.selectPreviousRow(6, 7, 3), 3);
    compare(Nav.selectPreviousRow(0, 7, 3), 6); // wraps to last row, same column
    compare(Nav.selectPreviousRow(2, 7, 3), 6); // wraps, column missing -> last item
    compare(Nav.selectPreviousRow(1, 0, 3), 1);
  }

  function test_selectNextColumn() {
    compare(Nav.selectNextColumn(0, 7, 3), 1);
    compare(Nav.selectNextColumn(2, 7, 3), 3); // end of row -> next row
    compare(Nav.selectNextColumn(6, 7, 3), 0); // last item wraps to start
    compare(Nav.selectNextColumn(1, 0, 3), 1);
  }

  function test_selectPreviousColumn() {
    compare(Nav.selectPreviousColumn(1, 7, 3), 0);
    compare(Nav.selectPreviousColumn(3, 7, 3), 2); // start of row -> previous row end
    compare(Nav.selectPreviousColumn(0, 7, 3), 6); // wraps to last item
    compare(Nav.selectPreviousColumn(0, 9, 3), 8);
    compare(Nav.selectPreviousColumn(1, 0, 3), 1);
  }
}
