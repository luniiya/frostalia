pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Helpers/Lyrics.js" as Lyrics
import qs.Commons

// Synced lyrics for the track that is playing. While Rufin plays and its Web
// Controller is on, they stream from Rufin (/api/lyrics/events: the lyrics Rufin shows,
// timed word by word when it has the timing). For other players, or when the controller
// is off, they come from LRCLIB (timed by line). Works only while a widget uses it.
Singleton {
  id: root

  // { start, end, text, words } per line, see Helpers/Lyrics.js
  property var lines: []
  // "idle", "loading", "ready", "none" (nothing found) or "instrumental"
  property string state: "idle"
  // "rufin" or "lrclib" once there are lines
  property string source: ""

  property var _users: ({})
  readonly property bool active: Object.keys(_users).length > 0

  function registerUser(id) {
    _users[id] = true;
    _users = Object.assign({}, _users);
  }

  function unregisterUser(id) {
    delete _users[id];
    _users = Object.assign({}, _users);
  }

  // ===== The track =====

  readonly property bool rufinPlaying: Lyrics.isRufin(MediaService.playerIdentity, MediaService.currentPlayer?.desktopEntry)
  readonly property string trackKey: [MediaService.trackTitle, MediaService.trackArtist, Math.round(MediaService.trackLength)].join("␟")
  readonly property bool useRufin: active && rufinPlaying && rufin.endpoint.enabled && rufin.token !== ""

  onTrackKeyChanged: refresh()
  onActiveChanged: refresh()
  onUseRufinChanged: refresh()

  function refresh() {
    lyricsTimer.restart();
  }

  // Let a track change settle (title and artist arrive one after the other)
  Timer {
    id: lyricsTimer
    interval: 250
    onTriggered: root.load()
  }

  function setLines(state, source, lines) {
    root.lines = lines;
    root.source = lines.length ? source : "";
    root.state = state;
  }

  function load() {
    if (!active || MediaService.trackTitle === "") {
      setLines("idle", "", []);
      return;
    }
    if (useRufin) {
      // The stream delivers them; (re)start it if it isn't running, and ask Rufin to
      // load them in case its own lyrics view hasn't
      if (!rufinStream.running)
        rufinStream.running = true;
      rufinLoad.running = false;
      rufinLoad.running = true;
      return;
    }
    rufinStream.running = false;
    loadLrclib(trackKey, MediaService.trackTitle, MediaService.trackArtist, MediaService.trackAlbum, MediaService.trackLength);
  }

  // ===== Rufin =====

  QtObject {
    id: rufin
    readonly property string home: Quickshell.env("HOME")
    // The Flatpak's config first, then a native install's
    readonly property var endpoint: {
      const flatpak = Lyrics.rufinEndpoint(flatpakSettings.text());
      return flatpak.enabled ? flatpak : Lyrics.rufinEndpoint(nativeSettings.text());
    }
    readonly property string token: endpoint.enabled ? Lyrics.rufinToken((Lyrics.rufinEndpoint(flatpakSettings.text()).enabled ? flatpakSecrets : nativeSecrets).text()) : ""
  }

  FileView {
    id: flatpakSettings
    path: rufin.home + "/.var/app/io.github.screwys.Rufin/config/rufin/settings.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: flatpakSecrets
    path: rufin.home + "/.var/app/io.github.screwys.Rufin/config/rufin/secrets.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: nativeSettings
    path: rufin.home + "/.config/rufin/settings.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: nativeSecrets
    path: rufin.home + "/.config/rufin/secrets.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
  }

  Process {
    id: rufinStream
    // The token goes in through the environment, not the command line
    command: ["sh", "-c", "exec curl -sfN --no-buffer -H \"Authorization: Bearer $RUFIN_TOKEN\" \"$1/api/lyrics/events\"", "sh", rufin.endpoint.url]
    environment: ({
                    "RUFIN_TOKEN": rufin.token
                  })
    stdout: SplitParser {
      onRead: line => {
        const data = Lyrics.eventData(line);
        if (!data)
          return;
        const parsed = Lyrics.fromRufin(data);
        const state = parsed.state === "ready" ? "ready" : parsed.state === "empty" ? "none" : parsed.state;
        root.setLines(state, "rufin", parsed.lines);
      }
    }
    onExited: code => {
      // Rufin closed or the controller went away: try again in a moment, and use
      // LRCLIB meanwhile
      if (root.useRufin) {
        Logger.d("Lyrics", "Rufin lyrics stream ended:", code);
        root.loadLrclib(root.trackKey, MediaService.trackTitle, MediaService.trackArtist, MediaService.trackAlbum, MediaService.trackLength);
        rufinRetry.restart();
      }
    }
  }

  Process {
    id: rufinLoad
    command: ["sh", "-c", "exec curl -sf -X POST -H \"Authorization: Bearer $RUFIN_TOKEN\" \"$1/api/lyrics\"", "sh", rufin.endpoint.url]
    environment: ({
                    "RUFIN_TOKEN": rufin.token
                  })
  }

  Timer {
    id: rufinRetry
    interval: 5000
    onTriggered: {
      if (root.useRufin && !rufinStream.running)
        rufinStream.running = true;
    }
  }

  // ===== LRCLIB =====

  // trackKey → { state, lines }, so replaying a track doesn't ask again
  property var _lrclibCache: ({})

  function loadLrclib(key, title, artist, album, duration) {
    const cached = _lrclibCache[key];
    if (cached) {
      setLines(cached.state, "lrclib", cached.lines);
      return;
    }
    setLines("loading", "lrclib", []);
    const clean = Lyrics.cleanTitle(title);
    request(Lyrics.lrclibGetUrl(clean, artist, album, duration), (status, body) => {
      if (status === 200 && body && body.syncedLyrics)
        return finishLrclib(key, body);
      if (status === 200 && body && body.instrumental)
        return finishLrclib(key, {
                              "instrumental": true
                            });
      searchLrclib(key, Lyrics.lrclibSearchUrls(title, artist), duration);
    });
  }

  // Try each search in turn until one has synced lyrics of the right length
  function searchLrclib(key, urls, duration) {
    if (urls.length === 0)
      return finishLrclib(key, null, true);
    request(urls[0], (status, results) => {
      const found = status === 200 ? Lyrics.pickLrclib(results, duration) : null;
      if (found || !Lyrics.lrclibSettled(status))
        return finishLrclib(key, found, Lyrics.lrclibSettled(status));
      searchLrclib(key, urls.slice(1), duration);
    });
  }

  // `settled`: false after a network error, so the track is asked again next time
  function finishLrclib(key, result, settled) {
    const entry = result && result.instrumental ? {
                                                    "state": "instrumental",
                                                    "lines": []
                                                  } : result && result.syncedLyrics ? {
                                                                                        "state": "ready",
                                                                                        "lines": Lyrics.parseLrc(result.syncedLyrics)
                                                                                      } : {
      "state": "none",
      "lines": []
    };
    if (settled !== false)
      _lrclibCache[key] = entry;
    // Only if the track is still the same and Rufin hasn't taken over
    if (key === trackKey && !(useRufin && rufinStream.running && source === "rufin"))
      setLines(entry.state, "lrclib", entry.lines);
  }

  function request(url, done) {
    const xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      let body = null;
      try {
        body = JSON.parse(xhr.responseText);
      } catch (e) {}
      done(xhr.status, body);
    };
    xhr.open("GET", url);
    xhr.send();
  }

  // ===== The player's clock =====
  // Quickshell runs a player's position on from its last report, so a player that
  // stalls (buffering) without saying so drifts ahead by seconds. While lyrics show,
  // read the real position from the player once a second.

  // The player's position in seconds, and Date.now() when it was read
  signal positionSampled(real position, real at)
  readonly property string playerBus: MediaService.currentPlayer?.dbusName ?? ""
  property real _probeAt: 0

  Timer {
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: root.active && MediaService.isPlaying && root.playerBus !== ""
    onTriggered: {
      if (positionProbe.running)
        return;
      root._probeAt = Date.now();
      positionProbe.running = true;
    }
  }

  Process {
    id: positionProbe
    command: ["busctl", "--user", "get-property", root.playerBus, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Position"]
    stdout: StdioCollector {
      onStreamFinished: {
        const position = Lyrics.busctlPosition(text);
        if (position >= 0)
          root.positionSampled(position, (root._probeAt + Date.now()) / 2);
      }
    }
  }
}
