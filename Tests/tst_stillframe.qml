import QtQuick
import QtTest
import "../Helpers/StillFrame.js" as StillFrame

TestCase {
  name: "StillFrame"

  function test_isGif_data() {
    return [
          {
            "tag": "gif",
            "path": "/w/a.gif",
            "gif": true
          },
          {
            "tag": "upper case",
            "path": "/w/A.GIF",
            "gif": true
          },
          {
            "tag": "png",
            "path": "/w/a.png",
            "gif": false
          },
          {
            "tag": "gif in a folder name",
            "path": "/w/gif/a.jpg",
            "gif": false
          },
          {
            "tag": "empty",
            "path": "",
            "gif": false
          }
        ];
  }

  function test_isGif(data) {
    compare(StillFrame.isGif(data.path), data.gif);
  }

  function test_gif_goes_through_ffmpeg() {
    const cmd = StillFrame.magickFirstFrame("/w/it's.gif");
    // ffmpeg stops after one frame; magick never sees the GIF itself
    compare(cmd, "ffmpeg -v error -nostdin -threads 1 -i '/w/it'\\''s.gif' -frames:v 1 -f image2pipe -c:v png - | " + StillFrame.magickLimits + "magick png:-");
    verify(cmd.indexOf(".gif[0]") < 0);
  }

  function test_still_goes_to_magick_with_caps() {
    compare(StillFrame.magickFirstFrame("/w/a.png"), "MAGICK_MEMORY_LIMIT=1GiB MAGICK_MAP_LIMIT=2GiB MAGICK_DISK_LIMIT=1GiB magick '/w/a.png[0]'");
  }

  function test_background_is_niced() {
    // The caps come before nice, or nice would try to run them as the command
    compare(StillFrame.magickFirstFrame("/w/a.png", true), StillFrame.magickLimits + "nice -n 19 magick '/w/a.png[0]'");
    const gif = StillFrame.magickFirstFrame("/w/a.gif", true);
    verify(gif.startsWith("nice -n 19 ffmpeg"));
    verify(gif.endsWith("| " + StillFrame.magickLimits + "nice -n 19 magick png:-"));
  }
}
