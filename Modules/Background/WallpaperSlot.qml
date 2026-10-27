import QtQuick

// One wallpaper picture. WallpaperLayer.qml makes a new one for every change and
// destroy()s it as soon as it has been blended out, so a texture is never left behind
// for a reassigned `source` to (maybe) free. After SekaiPop's WallpaperTextureSlot
// (github.com/Blapples/SekaiPop, GPL-3.0).
Image {
  anchors.fill: parent
  fillMode: Image.PreserveAspectCrop
  asynchronous: true
  smooth: true
  // Already cut to the screen's size (ImageCacheService.getScreenWallpaper), so it is
  // drawn 1:1 and mipmaps would never be sampled
  mipmap: false
  // This item is the only owner of its pixels; a second copy in the pixmap cache would
  // outlive it
  cache: false
  // Only while a transition samples it as a texture (WallpaperLayer.bindRole)
  layer.enabled: false
  layer.smooth: true
}
