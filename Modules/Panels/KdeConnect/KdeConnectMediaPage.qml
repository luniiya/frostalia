import QtQuick
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Widgets

// Controls whatever plays on the phone.
ColumnLayout {
  id: root
  required property var nav

  spacing: Style.marginM

  KdeConnectPageHeader {
    Layout.fillWidth: true
    nav: root.nav
    title: I18n.tr("kdeconnect.media.title")
  }

  KdeConnectMediaControls {
    Layout.fillWidth: true
    Layout.fillHeight: true
    expanded: true
  }
}
