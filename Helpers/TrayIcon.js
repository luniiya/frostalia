.pragma library

// Tray icon source resolution and colorize parameters. Kept free of
// QML/Quickshell dependencies so it can be unit tested (see Tests/tst_trayicon.qml).

var themePrefix = "image://icon/";

// Items may ship their own icon directory as "image://icon/<name>?path=<dir>"
function sourceFromIcon(icon) {
  if (!icon)
    return "";
  if (icon.indexOf("?path=") !== -1) {
    var chunks = icon.split("?path=");
    var name = chunks[0];
    var fileName = name.substring(name.lastIndexOf("/") + 1);
    return "file://" + chunks[1] + "/" + fileName;
  }
  return icon;
}

// Theme icon name of an "image://icon/<name>" source, "" for pixmaps and files
function themeIconName(source) {
  if (!source || source.indexOf(themePrefix) !== 0)
    return "";
  var name = source.substring(themePrefix.length);
  var query = name.indexOf("?");
  return query === -1 ? name : name.substring(0, query);
}

// Icon names worth trying for a tray item, most specific first.
// Apps often request names the user's theme lacks (e.g. fcitx asks for
// "input-keyboard-symbolic"), so also try plain variants and the app's own id.
function candidateNames(iconName, id, title) {
  var names = [];
  function add(n) {
    if (n && names.indexOf(n) === -1)
      names.push(n);
  }

  if (iconName) {
    add(iconName);
    var plain = iconName.replace(/-symbolic$/, "");
    add(plain);
    add(plain.replace(/-?(dark|light)$/, ""));
  }

  var labels = [id, title];
  for (var i = 0; i < labels.length; i++) {
    var label = String(labels[i] || "").trim().toLowerCase();
    if (!label)
      continue;
    add(label);
    add(label.replace(/\s+/g, "-"));
    // Reverse-domain ids: "org.kde.kdeconnect" -> "kdeconnect"
    if (label.indexOf(".") !== -1)
      add(label.split(".").pop());
  }
  return names;
}

// Source to display for a tray item. lookup(name) returns a loadable source
// for a theme icon name, or "" when the theme doesn't have it. Returns "" when
// nothing resolves so the caller can show a placeholder instead of the
// "missing image" checkerboard.
function resolve(icon, id, title, lookup) {
  var source = sourceFromIcon(icon);
  var name = themeIconName(source);
  if (!name)
    return source;

  var names = candidateNames(name, id, title);
  for (var i = 0; i < names.length; i++) {
    var found = lookup(names[i]);
    if (found)
      return found;
  }
  return "";
}

// ----- colorize -----

// "monochrome" flattens icons to one theme color. "duotone" maps each pixel's
// luminance onto a gradient between two theme colors, so shading survives.
var colorizeStyles = ["monochrome", "duotone"];

function normalizeStyle(style) {
  return colorizeStyles.indexOf(style) !== -1 ? style : "monochrome";
}

// Shader mode plus the Color roles for dark and light pixels.
// Duotone keeps "darker pixel -> darker color" in both theme modes.
function colorizeParams(style, darkMode) {
  if (normalizeStyle(style) === "duotone") {
    return {
      "mode": 3.0,
      "lowRole": darkMode ? "mPrimary" : "mOnSurface",
      "highRole": darkMode ? "mOnSurface" : "mPrimary"
    };
  }
  // Monochrome ramps between the two text colors: both contrast with the bar
  // (unlike the old light-mode mSurfaceVariant, which nearly matched it), and
  // the ramp keeps shading instead of flattening icons to one solid color
  return {
    "mode": 3.0,
    "lowRole": darkMode ? "mOnSurfaceVariant" : "mOnSurface",
    "highRole": darkMode ? "mOnSurface" : "mOnSurfaceVariant"
  };
}
