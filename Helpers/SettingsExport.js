.pragma library

function localPath(url) {
  const match = /^file:\/\/(?:localhost)?(\/.*)$/.exec(String(url || ""));
  if (!match)
    return "";
  try {
    return decodeURIComponent(match[1]);
  } catch (_) {
    return "";
  }
}
