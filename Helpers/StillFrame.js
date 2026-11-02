.pragma library

// Shell commands that read one still frame of an image into ImageMagick without
// running the machine out of memory (Tests/tst_stillframe.qml).
//
// ImageMagick decodes every frame of a GIF even when asked for the first one
// (`file.gif[0]`), at 8 bytes a pixel: a 600-frame 2560x1440 GIF is about 18 GB, and a
// few of those at once filled RAM and swap until systemd-oomd killed the session.
// ffmpeg stops after the first frame (0.2 s and 100 MB for the same file), so GIFs go
// through it. Every magick also runs with hard resource caps: past them it fails
// instead of growing, so a huge picture costs a failed copy, never the desktop.

var magickLimits = "MAGICK_MEMORY_LIMIT=1GiB MAGICK_MAP_LIMIT=2GiB MAGICK_DISK_LIMIT=1GiB ";

function quote(s) {
  return "'" + String(s).replace(/'/g, "'\\''") + "'";
}

function isGif(path) {
  return /\.gif$/i.test(String(path || ""));
}

// The start of a command that reads the first frame of `path` into magick; append the
// operations and the output file. `background`: lowest CPU priority, for pre-scaling.
function magickFirstFrame(path, background) {
  var nice = background ? "nice -n 19 " : "";
  if (isGif(path))
    return nice + "ffmpeg -v error -nostdin -threads 1 -i " + quote(path) + " -frames:v 1 -f image2pipe -c:v png - | " + magickLimits + nice + "magick png:-";
  // The caps go before `nice`: after it, nice would take them for the command to run
  return magickLimits + nice + "magick " + quote(path + "[0]");
}
