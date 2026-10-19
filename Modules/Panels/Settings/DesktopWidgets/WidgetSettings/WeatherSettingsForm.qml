import QtQuick
import QtQuick.Layouts
import qs.Commons

// Base for the weather widget settings: reads a key from the widget data with
// the registry default as fallback, and saves the whole object on change.
ColumnLayout {
  id: root
  spacing: Style.marginM

  property var widgetData: null
  property var widgetMetadata: null
  property var values: Object.assign({}, widgetMetadata || {}, widgetData || {})

  signal settingsChanged(var settings)

  function value(key) {
    return values[key];
  }

  function set(key, newValue) {
    const next = Object.assign({}, values);
    next[key] = newValue;
    values = next;
    settingsChanged(Object.assign({}, widgetData || {}, next));
  }
}
