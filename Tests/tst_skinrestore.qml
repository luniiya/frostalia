import QtQuick
import QtTest

// A style skin that restyles its card through Bindings (Styles/keycap/Card.qml) has to
// hand the card's own values back when the style changes and the skin is unloaded
TestCase {
  id: testCase
  name: "SkinRestore"

  Component {
    id: card
    Rectangle {
      border.width: 1
      property alias skin: loader
      Loader {
        id: loader
        sourceComponent: skinComponent
      }
    }
  }

  // Like the keycap Card skin: off as it is destroyed, so the Bindings restore
  Component {
    id: skinComponent
    Item {
      id: skin
      property bool alive: true
      Component.onDestruction: alive = false
      Binding {
        when: skin.alive
        target: skin.parent ? skin.parent.parent : null
        property: "border.width"
        value: 4
      }
    }
  }

  function test_unloading_the_skin_restores_the_card() {
    const c = createTemporaryObject(card, testCase);
    compare(c.border.width, 4);
    c.skin.sourceComponent = null;
    compare(c.border.width, 1);
  }
}
