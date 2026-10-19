pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.UI

// Bridge to kdeconnectd through the frostalia-kdeconnect helper
// (Tools/kdeconnect), which speaks JSON lines on stdin/stdout.
Singleton {
  id: root

  readonly property bool enabled: Settings.data.kdeConnect.enabled
  readonly property string helper: Quickshell.env("FROSTALIA_KDECONNECT_HELPER") || (Quickshell.shellDir + "/Tools/kdeconnect/target/release/frostalia-kdeconnect")

  // Helper state
  property bool running: false
  property bool available: false // kdeconnectd is on the bus
  property string selfName: ""
  property var devices: []
  property var pairingRequests: []
  property string lastError: ""

  // The one phone the UI shows (see KdeConnect.activeDevice).
  readonly property var pairedDevices: KdeConnect.pairedDevices(devices)
  readonly property var unpairedDevices: devices.filter(d => !d.paired && d.reachable)
  readonly property var activeDevice: KdeConnect.activeDevice(devices, Settings.data.kdeConnect.device)
  readonly property string activeId: activeDevice ? activeDevice.id : ""
  readonly property bool online: KdeConnect.isOnline(activeDevice)
  // "77% · LTE" line under the device name.
  readonly property string statusText: KdeConnect.statusLine(activeDevice, {
                                                               offline: I18n.tr("kdeconnect.status.offline"),
                                                               charging: I18n.tr("common.charging"),
                                                               connected: I18n.tr("common.connected")
                                                             })

  // Messages for the active device
  property var conversations: []
  property var contacts: []
  property bool conversationsLoaded: false
  readonly property int unreadCount: KdeConnect.unreadCount(conversations)
  property int openThread: -1
  property var threadMessages: []
  property bool threadLoading: false
  property bool threadComplete: false
  property int pendingSerial: 0
  property int threadCountBefore: 0

  readonly property int threadPageSize: 50

  function init() {
    Logger.i("KdeConnect", "Service started");
  }

  // ---------------------------------------------------------------------------
  // Commands

  function send(command) {
    if (!process.running) {
      Logger.w("KdeConnect", "Helper not running; dropped", command.cmd);
      return false;
    }
    process.write(JSON.stringify(command) + "\n");
    return true;
  }

  function sendToDevice(cmd, fields) {
    if (!activeId)
      return false;
    return send(Object.assign({
                                cmd: cmd,
                                device: activeId
                              }, fields || {}));
  }

  function selectDevice(id) {
    if (id === activeId)
      return;
    Settings.data.kdeConnect.device = id;
  }

  function refresh() {
    send({
           cmd: "refresh"
         });
  }

  function rename(name) {
    send({
           cmd: "setAnnouncedName",
           name: name
         });
  }

  function ring() {
    sendToDevice("ring");
  }
  function ping() {
    sendToDevice("ping");
  }
  function sendClipboard() {
    sendToDevice("sendClipboard");
  }
  function shareFiles(paths) {
    const urls = KdeConnect.shareUrls(paths);
    if (urls.length)
      sendToDevice("shareUrls", {
                     urls: urls
                   });
  }
  function shareText(text) {
    if (text)
      sendToDevice("shareText", {
                     text: text
                   });
  }

  // Files
  function mount() {
    sendToDevice("mount");
  }
  function unmount() {
    sendToDevice("unmount");
  }
  function browse() {
    sendToDevice("browse");
  }
  function openPath(path) {
    Qt.openUrlExternally("file://" + encodeURI(path));
  }

  // Media
  function mediaAction(action) {
    sendToDevice("mediaAction", {
                   action: action
                 });
  }
  function mediaSetPosition(ms) {
    sendToDevice("mediaSetPosition", {
                   position: Math.round(ms)
                 });
  }
  function mediaSetVolume(volume) {
    sendToDevice("mediaSetVolume", {
                   volume: Math.round(volume)
                 });
  }
  function mediaSetPlayer(player) {
    sendToDevice("mediaSetPlayer", {
                   player: player
                 });
  }

  // Remote input
  function moveCursor(dx, dy) {
    if (dx || dy)
      sendToDevice("moveCursor", {
                     dx: dx,
                     dy: dy
                   });
  }
  function click(button) {
    sendToDevice("click", {
                   button: button
                 });
  }
  function scroll(dx, dy) {
    sendToDevice("scroll", {
                   dx: dx,
                   dy: dy
                 });
  }
  function keyPress(key, text, modifiers) {
    const fields = KdeConnect.keyPress(key, text, modifiers);
    if (!fields)
      return false;
    sendToDevice("keyPress", fields);
    return true;
  }
  function typeText(text) {
    if (text)
      sendToDevice("keyPress", {
                     key: text
                   });
  }

  // Phone notifications
  function dismissNotification(id) {
    sendToDevice("notificationDismiss", {
                   id: id
                 });
  }
  function replyNotification(id, text) {
    sendToDevice("notificationReply", {
                   id: id,
                   text: text
                 });
  }

  // Pairing and device settings
  function requestPairing(id) {
    send({
           cmd: "requestPairing",
           device: id
         });
  }
  function acceptPairing(id) {
    send({
           cmd: "acceptPairing",
           device: id
         });
  }
  function rejectPairing(id) {
    send({
           cmd: "rejectPairing",
           device: id
         });
  }
  function unpair(id) {
    send({
           cmd: "unpair",
           device: id
         });
  }
  function setPluginEnabled(plugin, enabled) {
    sendToDevice("setPluginEnabled", {
                   plugin: plugin,
                   enabled: enabled
                 });
  }
  function setRunCommands(commands) {
    sendToDevice("setRunCommands", {
                   commands: KdeConnect.cleanCommands(commands)
                 });
  }

  // ---------------------------------------------------------------------------
  // Messages

  function loadConversations() {
    if (online)
      sendToDevice("requestConversations");
  }

  function syncContacts() {
    sendToDevice("syncContacts");
  }

  function openConversation(thread) {
    openThread = thread;
    threadMessages = [];
    threadComplete = false;
    loadOlderMessages();
  }

  function loadOlderMessages() {
    if (openThread < 0 || threadLoading || threadComplete)
      return;
    threadLoading = true;
    threadCountBefore = threadMessages.filter(m => !m.pending).length;
    sendToDevice("requestThread", {
                   thread: openThread,
                   start: threadCountBefore,
                   count: threadPageSize
                 });
  }

  function closeConversation() {
    openThread = -1;
    threadMessages = [];
    threadLoading = false;
  }

  function reply(text) {
    const body = String(text || "").trim();
    if (!body || openThread < 0)
      return;
    if (!sendToDevice("replyThread", {
                        thread: openThread,
                        text: body
                      }))
      return;
    threadMessages = KdeConnect.mergeMessage(threadMessages, KdeConnect.pendingMessage(openThread, body, Date.now(), pendingSerial++));
  }

  function sendNewMessage(addresses, text) {
    const body = String(text || "").trim();
    const to = (addresses || []).map(a => String(a).trim()).filter(a => a !== "");
    if (!body || !to.length)
      return false;
    return sendToDevice("sendSms", {
                          addresses: to,
                          text: body
                        });
  }

  function contactName(number) {
    return KdeConnect.displayName(number, contacts);
  }

  function threadTitle(addresses) {
    return KdeConnect.threadTitle(addresses, contacts);
  }

  // Short timestamp for thread lists and bubbles.
  function formatStamp(date) {
    const d = new Date(date);
    switch (KdeConnect.timeKind(date, Date.now())) {
    case "time":
      return I18n.locale.toString(d, I18n.locale.timeFormat(Locale.ShortFormat));
    case "weekday":
      return I18n.locale.dayName(d.getDay(), Locale.ShortFormat);
    default:
      return I18n.locale.toString(d, I18n.locale.dateFormat(Locale.ShortFormat));
    }
  }

  function formatDay(date) {
    const d = new Date(date);
    return KdeConnect.timeKind(date, Date.now()) === "time" ? I18n.tr("kdeconnect.messages.today") : I18n.locale.toString(d, "dddd d MMMM yyyy");
  }

  function contactPhoto(number) {
    const contact = KdeConnect.contactFor(number, contacts);
    return contact ? contact.photo : "";
  }

  function resetMessages() {
    conversations = [];
    contacts = [];
    conversationsLoaded = false;
    closeConversation();
  }

  onActiveIdChanged: resetMessages()
  onOnlineChanged: {
    if (online && !conversationsLoaded)
      loadConversations();
  }

  // ---------------------------------------------------------------------------
  // Helper output

  function handle(line) {
    let event;
    try {
      event = JSON.parse(line);
    } catch (e) {
      Logger.w("KdeConnect", "Unreadable helper output:", line);
      return;
    }
    switch (event.type) {
    case "state":
      available = event.available;
      selfName = event.selfName || "";
      devices = event.devices || [];
      if ((event.pairingRequests || []).some(id => pairingRequests.indexOf(id) < 0))
        ToastService.showNotice(I18n.tr("kdeconnect.toast.pairing-request"), I18n.tr("kdeconnect.toast.pairing-request-description"), "device-mobile");
      pairingRequests = event.pairingRequests || [];
      break;
    case "conversations":
      if (event.device !== activeId)
        return;
      conversations = KdeConnect.sortThreads(event.messages);
      conversationsLoaded = true;
      break;
    case "message":
      if (event.device !== activeId)
        return;
      conversations = KdeConnect.upsertThread(conversations, event.message);
      if (event.message.thread === openThread)
        threadMessages = KdeConnect.mergeMessage(threadMessages, event.message);
      break;
    case "conversationLoaded":
      if (event.device === activeId && event.thread === openThread) {
        // A short page means the start of the thread was reached.
        threadLoading = false;
        threadComplete = threadMessages.filter(m => !m.pending).length - threadCountBefore < threadPageSize;
      }
      break;
    case "conversationRemoved":
      if (event.device !== activeId)
        return;
      conversations = KdeConnect.removeThread(conversations, event.thread);
      if (event.thread === openThread)
        closeConversation();
      break;
    case "contacts":
      if (event.device === activeId)
        contacts = event.contacts || [];
      break;
    case "call":
      handleCall(event);
      break;
    case "shareReceived":
      ToastService.showNotice(I18n.tr("kdeconnect.toast.file-received"), decodeURIComponent(String(event.url).replace(/^file:\/\//, "")), "file-download", 6000, I18n.tr("kdeconnect.open"), () => Qt.openUrlExternally(event.url));
      break;
    case "pairingFailed":
      ToastService.showWarning(I18n.tr("kdeconnect.toast.pairing-failed"), event.error);
      break;
    case "error":
      lastError = event.message;
      Logger.w("KdeConnect", event.message);
      if (threadLoading && /RequestThread/.test(event.message))
        threadLoading = false;
      break;
    }
  }

  function handleCall(event) {
    const who = event.name || contactName(event.number) || I18n.tr("kdeconnect.unknown-caller");
    if (event.event === "ringing")
      ToastService.showNotice(I18n.tr("kdeconnect.toast.incoming-call"), who, "phone-incoming", 8000);
    else if (event.event === "missedCall")
      ToastService.showNotice(I18n.tr("kdeconnect.toast.missed-call"), who, "phone-call", 8000);
  }

  // ---------------------------------------------------------------------------
  // Helper process

  property int restartDelay: 1000

  Process {
    id: process
    command: [root.helper]
    running: root.enabled // set imperatively from here on, see onEnabledChanged
    stdinEnabled: true
    stdout: SplitParser {
      onRead: line => root.handle(line)
    }
    stderr: SplitParser {
      onRead: line => Logger.w("KdeConnect", line)
    }
    onStarted: {
      root.running = true;
      root.restartDelay = 1000;
      Logger.i("KdeConnect", "Helper started");
    }
    onExited: function (exitCode) {
      root.running = false;
      root.available = false;
      if (root.enabled) {
        Logger.w("KdeConnect", "Helper exited with code", exitCode, "- restarting in", root.restartDelay, "ms");
        restartTimer.interval = root.restartDelay;
        root.restartDelay = Math.min(30000, root.restartDelay * 2);
        restartTimer.restart();
      }
    }
  }

  Timer {
    id: restartTimer
    onTriggered: {
      if (root.enabled)
        process.running = true;
    }
  }

  onEnabledChanged: {
    process.running = enabled;
    if (!enabled) {
      restartTimer.stop();
      running = false;
      available = false;
      devices = [];
      pairingRequests = [];
      resetMessages();
    }
  }
}
