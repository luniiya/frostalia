import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Services.UI
import qs.Widgets

// Dashboard + drill-down: the home page is a UI style view, every other page
// is shared. Pages get this item as `nav`.
Item {
  id: root
  required property var panel

  property var stack: KdeConnect.popPage(null)
  readonly property var current: stack[stack.length - 1]
  readonly property bool isHome: current.page === "home"
  readonly property real homeHeight: (homeView.item?.implicitHeight || 0) + Style.margin2L

  readonly property var pageFiles: ({
                                      messages: "KdeConnectMessagesPage.qml",
                                      thread: "KdeConnectThreadPage.qml",
                                      compose: "KdeConnectComposePage.qml",
                                      notifications: "KdeConnectNotificationsPage.qml",
                                      media: "KdeConnectMediaPage.qml",
                                      remote: "KdeConnectRemotePage.qml",
                                      files: "KdeConnectFilesPage.qml",
                                      device: "KdeConnectDevicePage.qml"
                                    })

  function push(page, props) {
    stack = KdeConnect.pushPage(stack, page, props);
  }
  function pop() {
    stack = KdeConnect.popPage(stack);
  }
  function reset() {
    stack = KdeConnect.popPage(null);
  }
  function close() {
    panel.close();
  }

  // Feature pages and one-tap actions offered by the home views.
  readonly property var features: KdeConnect.availableFeatures(KdeConnectService.activeDevice)
  readonly property var actions: KdeConnect.availableActions(KdeConnectService.activeDevice)

  function featureTitle(id) {
    return I18n.tr("kdeconnect." + id + ".title");
  }

  function featureSubtitle(id) {
    const device = KdeConnectService.activeDevice;
    switch (id) {
    case "messages":
      if (KdeConnectService.unreadCount > 0)
        return I18n.tr("kdeconnect.messages.unread", {
                         count: KdeConnectService.unreadCount
                       });
      return KdeConnectService.conversations.length ? KdeConnectService.threadTitle(KdeConnectService.conversations[0].addresses) : "";
    case "notifications":
      return device.notifications.length ? I18n.tr("kdeconnect.notifications.count", {
                                                     count: device.notifications.length
                                                   }) : I18n.tr("kdeconnect.notifications.empty");
    case "media":
      return device.media && device.media.title ? device.media.title : I18n.tr("kdeconnect.media.nothing-playing");
    case "remote":
      return I18n.tr("kdeconnect.remote.subtitle");
    case "files":
      return device.sftp && device.sftp.mounted ? I18n.tr("kdeconnect.files.mounted") : I18n.tr("kdeconnect.files.subtitle");
    }
    return "";
  }

  function actionTitle(id) {
    return I18n.tr("kdeconnect.actions." + id);
  }

  function runAction(id) {
    switch (id) {
    case "ring":
      KdeConnectService.ring();
      break;
    case "ping":
      KdeConnectService.ping();
      break;
    case "clipboard":
      KdeConnectService.sendClipboard();
      ToastService.showNotice(I18n.tr("kdeconnect.toast.clipboard-sent"), "", "clipboard");
      break;
    case "share":
      pickFiles();
      break;
    }
  }

  function openThread(thread) {
    push("thread", {
           thread: thread.thread,
           addresses: thread.addresses
         });
  }

  function pickFiles() {
    filePicker.openFilePicker();
  }

  // Device switcher, like the media player source menu.
  function openDeviceMenu(item) {
    deviceMenu.model = KdeConnectService.pairedDevices.map(d => ({
      label: d.name + (d.reachable ? "" : " · " + I18n.tr("kdeconnect.status.offline")),
      action: "device:" + d.id,
      icon: KdeConnect.deviceIcon(d)
    })).concat([
                 {
                   label: I18n.tr("kdeconnect.pair-new-device"),
                   action: "pair",
                   icon: "plus"
                 }
               ]);
    deviceMenu.openAtItem(item, 0, item.height);
  }

  onCurrentChanged: {
    if (current.page !== "thread")
      KdeConnectService.closeConversation();
  }

  Connections {
    target: root.panel
    function onClosed() {
      root.reset();
    }
    function onOpened() {
      root.openPendingPage();
      if (KdeConnectService.online && !KdeConnectService.conversationsLoaded)
        KdeConnectService.loadConversations();
    }
    function onPendingPageChanged() {
      if (root.panel.isPanelOpen)
        root.openPendingPage();
    }
  }

  function openPendingPage() {
    const page = panel.pendingPage;
    if (!page)
      return;
    panel.pendingPage = "";
    reset();
    if (KdeConnectService.online)
      push(page);
  }

  Component.onCompleted: openPendingPage()

  Connections {
    target: KdeConnectService
    function onOnlineChanged() {
      root.stack = KdeConnect.reachablePages(root.stack, KdeConnectService.online);
    }
    function onActiveIdChanged() {
      root.reset();
    }
  }

  NStyleView {
    id: homeView
    anchors.fill: parent
    anchors.margins: Style.marginL
    visible: root.isHome
    surface: "kdeConnectHome"
    viewProperties: ({
                       nav: root
                     })
  }

  Loader {
    id: pageLoader
    anchors.fill: parent
    anchors.margins: Style.marginL
    active: !root.isHome
    visible: active
    property var entry: root.current
    onEntryChanged: {
      if (root.isHome)
        return;
      setSource(root.pageFiles[entry.page], Object.assign({
                                                            nav: root
                                                          }, entry.props));
    }
  }

  // Drop files anywhere on the panel to send them to the phone.
  DropArea {
    id: drop
    anchors.fill: parent
    enabled: KdeConnectService.online && KdeConnect.hasPlugin(KdeConnectService.activeDevice, "share")
    onDropped: event => {
      if (event.hasUrls) {
        KdeConnectService.shareFiles(event.urls.map(u => u.toString()));
        event.accept(Qt.CopyAction);
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: Style.marginS
    visible: drop.containsDrag
    radius: Style.radiusL
    color: Qt.alpha(ShellColors.mPrimary, 0.12)
    border.color: ShellColors.mPrimary
    border.width: Style.borderM
    ColumnLayout {
      anchors.centerIn: parent
      spacing: Style.marginS
      NIcon {
        Layout.alignment: Qt.AlignHCenter
        icon: "file-upload"
        pointSize: Style.fontSizeXXXL
        color: ShellColors.mPrimary
      }
      NText {
        Layout.alignment: Qt.AlignHCenter
        text: I18n.tr("kdeconnect.drop-to-send", {
                        device: KdeConnectService.activeDevice?.name || ""
                      })
        pointSize: Style.fontSizeM
        color: ShellColors.mPrimary
      }
    }
  }

  NContextMenu {
    id: deviceMenu
    width: Math.round(240 * Style.uiScaleRatio)
    onTriggered: action => {
      if (action === "pair")
        root.push("device");
      else
        KdeConnectService.selectDevice(action.substring(7));
    }
  }

  NFilePicker {
    id: filePicker
    title: I18n.tr("kdeconnect.send-files")
    selectionMode: "files"
    allowMultiSelection: true
    initialPath: Quickshell.env("HOME")
    onAccepted: paths => KdeConnectService.shareFiles(paths)
  }
}
