import QtQuick

// NSectionEditor's searchable picker requires a ListModel (an array is rejected).
ListModel {
  id: root
  property var widgetIds: []

  onWidgetIdsChanged: {
    clear();
    widgetIds.forEach(function (id) {
      append({
               key: id,
               name: id
             });
    });
  }
}
