import QtQuick
import QtQuick.Layouts
import "../../Helpers/WallpaperPicker.js" as WallpaperPicker
import "." as Keycap

import qs.Commons
import qs.Services.UI
import qs.Widgets

// Keycap wallpaper picker: a keycap case on top holds a tilted sticker title, a
// long cream search key, the color filters as little colored keycaps and the
// sort keys; the active filter and sort keys latch down. Below, the wallpapers
// are keycaps too: every strip leans the same way with an ink outline, cream
// ring and hard shadow, and the selected one stands upright, larger, with its
// file name on a sticker and the format as a corner sub-legend. Hint keys at the
// bottom list the keyboard controls. State and actions live in
// WallpaperPickerPanel.qml (`picker`).
Item {
  id: root

  property var picker

  readonly property real s: Style.uiScaleRatio
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")
  readonly property real depth: kit.depth

  function solid(c) {
    return Qt.rgba(c.r, c.g, c.b, 1);
  }

  // Opaque fills, so the hard shadow never shows through
  readonly property color caseFill: solid(Qt.tint(ShellColors.mSurface, Qt.alpha(ShellColors.mSurfaceVariant, 0.5)))
  readonly property color keyFill: solid(Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mSurface, 0.35)))
  readonly property color primaryFill: solid(ShellColors.mPrimary)

  // Opening animation (WallpaperPicker.introBar, introItem): the case grows from a
  // keycap, then the sticker, search, swatches, sort keys and count pop in
  readonly property real intro: picker.intro
  readonly property var bar: WallpaperPicker.introBar(intro)
  readonly property int introCount: WallpaperPicker.families.length + 8

  readonly property real stripHeight: Math.round(Math.min(height * 0.5, 600 * s))
  readonly property real centerHeight: Math.round(stripHeight * 1.08)

  readonly property var modeOptions: [
    {
      "key": "light",
      "icon": "sun",
      "label": I18n.tr("wallpaper-picker.mode.light")
    },
    {
      "key": "dark",
      "icon": "moon",
      "label": I18n.tr("wallpaper-picker.mode.dark")
    }
  ]

  readonly property var sortOptions: [
    {
      "key": "name",
      "icon": "sort-a-z",
      "label": I18n.tr("wallpaper-picker.sort.name")
    },
    {
      "key": "date",
      "icon": "calendar-time",
      "label": I18n.tr("wallpaper-picker.sort.date")
    },
    {
      "key": "hue",
      "icon": "palette",
      "label": I18n.tr("wallpaper-picker.sort.hue")
    }
  ]

  // Toolbar: one keycap case -------------------------------------------------

  Keycap.Key {
    id: toolbar
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: carousel.top
    anchors.bottomMargin: Math.round((36 - 24 * root.bar.lift) * root.s)
    readonly property real fullWidth: Math.min(parent.width - Style.margin2L * 2, toolbarRow.implicitWidth + Style.marginL * 2)
    width: Math.round(height + (fullWidth - height) * root.bar.grow)
    height: Math.round(64 * root.s)
    opacity: root.bar.opacity
    fillColor: root.caseFill
    inkColor: root.kit.ink
    ringColor: root.kit.ringFor(fillColor)
    radius: root.kit.radius * 1.5
    outlineWidth: root.kit.outline
    ringWidth: root.kit.ring
    depth: root.depth

    // Absorb clicks, so they don't close the picker
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    // Lays out at full width while the case grows around it
    Item {
      anchors.fill: parent
      clip: root.bar.grow < 1

      RowLayout {
        id: toolbarRow
        anchors.centerIn: parent
        width: toolbar.fullWidth - Style.marginL * 2
        height: parent.height
        spacing: Style.marginM

        Sticker {
          scale: WallpaperPicker.introItem(root.intro, 0, root.introCount)
          text: I18n.tr("wallpaper-picker.title")
          icon: "photo"
          body: root.primaryFill
          tilt: -3
        }

        // Light or dark folder (Ctrl+L / Ctrl+D); the active key latches down
        Row {
          spacing: Math.round(5 * root.s)
          scale: WallpaperPicker.introItem(root.intro, 1, root.introCount)

          Repeater {
            model: root.modeOptions
            delegate: PadKey {
              id: modeKey
              required property var modelData
              readonly property bool active: root.picker.pickMode === modelData.key
              width: Math.round(40 * root.s)
              height: Math.round(36 * root.s)
              fillColor: active ? root.primaryFill : root.keyFill
              radius: root.kit.smallRadius
              latched: active
              tooltip: modelData.label
              onClicked: root.picker.setPickMode(modelData.key)

              NIcon {
                anchors.centerIn: parent
                icon: modeKey.modelData.icon
                pointSize: Style.fontSizeL
                color: root.kit.readableOn(modeKey.fillColor)
              }
            }
          }
        }

        // Search key: typing anywhere goes here
        PadKey {
          scale: WallpaperPicker.introItem(root.intro, 2, root.introCount)
          Layout.preferredWidth: Math.round(280 * root.s)
          Layout.preferredHeight: Math.round(40 * root.s)
          fillColor: root.kit.cream
          radius: root.kit.smallRadius
          hoverLift: 0
          onClicked: root.picker.clearQuery()

          NIcon {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: Style.marginM
            anchors.verticalCenter: parent.verticalCenter
            icon: "search"
            pointSize: Style.fontSizeL
            color: root.kit.readableOn(root.kit.cream)
          }

          NText {
            id: queryText
            anchors.left: searchIcon.right
            anchors.leftMargin: Style.marginS
            anchors.right: parent.right
            anchors.rightMargin: Style.marginM
            anchors.verticalCenter: parent.verticalCenter
            text: root.picker.query || I18n.tr("wallpaper-picker.search")
            color: Qt.alpha(root.kit.readableOn(root.kit.cream), root.picker.query ? 1 : 0.55)
            pointSize: Style.fontSizeM
            font.weight: root.picker.query ? Style.fontWeightBold : Style.fontWeightMedium
            elide: Text.ElideLeft
          }

          // Block caret, like a terminal
          Rectangle {
            x: queryText.x + (root.picker.query ? Math.min(queryText.width, queryText.contentWidth) + Math.round(2 * root.s) : 0)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(8 * root.s)
            height: Math.round(18 * root.s)
            color: root.kit.ink
            SequentialAnimation on opacity {
              loops: Animation.Infinite
              running: true
              PauseAnimation {
                duration: 450
              }
              PropertyAction {
                value: 0
              }
              PauseAnimation {
                duration: 450
              }
              PropertyAction {
                value: 1
              }
            }
          }
        }

        // Color filters: little keycaps in the swatch color
        Row {
          spacing: Math.round(5 * root.s)

          SwatchKey {
            familyKey: ""
            introIndex: 3
            tooltip: I18n.tr("wallpaper-picker.all-colors")
          }

          Repeater {
            model: WallpaperPicker.families
            delegate: SwatchKey {
              required property var modelData
              required property int index
              introIndex: index + 4
              familyKey: modelData.key
              swatch: modelData.swatch
              tooltip: I18n.tr("wallpaper-picker.families." + modelData.key)
            }
          }
        }

        // Order keys; the active one latches down
        Row {
          spacing: Math.round(5 * root.s)

          Repeater {
            model: root.sortOptions
            delegate: PadKey {
              id: sortKey
              required property var modelData
              required property int index
              readonly property bool active: root.picker.sortBy === modelData.key
              scale: WallpaperPicker.introItem(root.intro, WallpaperPicker.families.length + 4 + index, root.introCount)
              width: sortRow.implicitWidth + Style.marginM * 2
              height: Math.round(36 * root.s)
              fillColor: active ? root.primaryFill : root.keyFill
              radius: root.kit.smallRadius
              latched: active
              onClicked: root.picker.setSort(modelData.key)

              Row {
                id: sortRow
                anchors.centerIn: parent
                spacing: Math.round(5 * root.s)
                NIcon {
                  anchors.verticalCenter: parent.verticalCenter
                  icon: sortKey.modelData.icon
                  pointSize: Style.fontSizeM
                  color: root.kit.readableOn(sortKey.fillColor)
                }
                NText {
                  anchors.verticalCenter: parent.verticalCenter
                  text: sortKey.modelData.label
                  pointSize: Style.fontSizeS
                  font.weight: Style.fontWeightBold
                  color: root.kit.readableOn(sortKey.fillColor)
                }
              }
            }
          }
        }

        NText {
          Layout.minimumWidth: implicitWidth
          scale: WallpaperPicker.introItem(root.intro, root.introCount - 1, root.introCount)
          text: I18n.tr("wallpaper-picker.count", {
                          "shown": root.picker.entries.length,
                          "total": root.picker.totalCount
                        })
          pointSize: Style.fontSizeS
          font.family: Style.fontFixed
          font.weight: Style.fontWeightBold
          color: ShellColors.mOnSurfaceVariant
        }
      }
    }
  }

  // Carousel ----------------------------------------------------------------

  NWallpaperCarousel {
    id: carousel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    height: root.centerHeight + root.depth * 2
    entries: root.picker.entries
    currentIndex: root.picker.selectedIndex
    centerHeight: root.centerHeight
    centerWidth: Math.round(root.centerHeight * 0.72)
    stripHeight: root.stripHeight
    stripWidth: Math.round(root.stripHeight * 0.14)
    gap: Math.round(12 * root.s)
    skew: -0.16
    mirror: false
    duration: root.kit.normal
    card: keycapCard
    intro: root.intro
    onCardClicked: index => root.picker.activate(index)
    onStepped: delta => root.picker.move(delta)
  }

  // Empty and loading states
  Sticker {
    anchors.centerIn: carousel
    visible: root.picker.entries.length === 0
    text: root.picker.loading ? I18n.tr("wallpaper-picker.loading") : root.picker.totalCount === 0 ? I18n.tr("wallpaper-picker.empty", {
                                                                                                               "folder": root.picker.folder
                                                                                                             }) : I18n.tr("wallpaper-picker.no-match")
    icon: root.picker.loading ? "photo" : "search"
    tilt: 2
  }

  // Hint keys, and indexing progress
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: carousel.bottom
    anchors.topMargin: Math.round(36 * root.s)
    spacing: Style.marginL
    opacity: WallpaperPicker.phase(root.intro, 0.75, 1)

    HintKey {
      keyLabel: "←→"
      hint: I18n.tr("wallpaper-picker.hints.navigate")
    }
    HintKey {
      keyLabel: "↑↓"
      hint: I18n.tr("wallpaper-picker.hints.colors")
    }
    HintKey {
      keyLabel: "Tab"
      hint: I18n.tr("wallpaper-picker.hints.sort")
    }
    HintKey {
      keyLabel: "^L ^D"
      hint: I18n.tr("wallpaper-picker.hints.mode")
    }
    HintKey {
      keyLabel: "⏎"
      hint: I18n.tr("wallpaper-picker.hints.apply")
    }
    HintKey {
      keyLabel: "Esc"
      hint: I18n.tr("wallpaper-picker.hints.close")
    }
    NText {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.picker.indexing && root.picker.indexedCount > 0
      text: I18n.tr("wallpaper-picker.indexing", {
                      "done": root.picker.indexedCount,
                      "total": root.picker.totalCount
                    })
      pointSize: Style.fontSizeXS
      font.family: Style.fontFixed
      color: ShellColors.mOnSurfaceVariant
    }
  }

  // Building blocks --------------------------------------------------------

  // A wallpaper keycap: the image sits inside the ink outline and cream ring
  Component {
    id: keycapCard

    Item {
      id: card
      property Item slot
      readonly property var entry: slot ? slot.entry : null
      readonly property real focusAmount: slot ? slot.focusAmount : 0
      readonly property real inset: root.kit.outline + root.kit.ring

      Keycap.Key {
        id: cap
        width: parent.width
        height: parent.height - root.depth
        fillColor: root.kit.cream
        inkColor: root.kit.ink
        ringColor: root.kit.cream
        radius: card.focusAmount > 0.5 ? root.kit.radius : root.kit.smallRadius
        outlineWidth: root.kit.outline
        ringWidth: root.kit.ring
        depth: root.depth * (1 + card.focusAmount)
        pressedDepth: root.kit.pressedDepth
        hoverLift: root.kit.hoverLift * 2
        duration: root.kit.fast
        overshoot: root.kit.overshoot
        pressed: card.slot ? card.slot.pressed : false
        hovered: card.slot ? card.slot.hovered && !card.slot.selected : false

        NWallpaperImage {
          anchors.fill: parent
          anchors.margins: card.inset
          entry: card.entry
          sharp: card.slot ? card.slot.sharp : false
          radius: Math.max(0, cap.radius - card.inset)
          decodeHeight: carousel.centerHeight
          placeholderColor: root.keyFill
        }

        // Format as a corner sub-legend
        Rectangle {
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: card.inset + Math.round(4 * root.s)
          width: badgeText.implicitWidth + Math.round(8 * root.s)
          height: Math.round(18 * root.s)
          radius: Math.round(4 * root.s)
          visible: badgeText.text !== "" && width < card.width - card.inset * 2 - Math.round(6 * root.s)
          color: root.kit.cream
          border.color: root.kit.ink
          border.width: Math.max(1, root.kit.outline - 1)

          NText {
            id: badgeText
            anchors.centerIn: parent
            text: WallpaperPicker.badge(card.entry ? card.entry.ext : "")
            pointSize: Style.fontSizeXXS
            font.family: Style.fontFixed
            font.weight: Style.fontWeightBold
            color: root.kit.readableOn(root.kit.cream)
          }
        }
      }

      // File name sticker of the selected card
      Sticker {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(36 * root.s)
        maxWidth: card.width - Math.round(24 * root.s)
        text: WallpaperPicker.title(card.entry)
        body: root.kit.cream
        tilt: -2
        opacity: Math.max(0, card.focusAmount * 2 - 1)
        visible: opacity > 0
        scale: 0.8 + 0.2 * card.focusAmount
      }
    }
  }

  // A clickable keycap. Children sit on the face and sink with it.
  component PadKey: Keycap.Key {
    id: padKey
    signal clicked
    property string tooltip
    readonly property bool containsMouse: padArea.containsMouse
    fillColor: root.keyFill
    inkColor: root.kit.ink
    ringColor: root.kit.ringFor(fillColor)
    outlineWidth: root.kit.outline
    ringWidth: root.kit.ring
    depth: root.depth
    pressedDepth: root.kit.pressedDepth
    hoverLift: root.kit.hoverLift
    duration: root.kit.fast
    overshoot: root.kit.overshoot
    pressed: padArea.pressed
    hovered: padArea.containsMouse
    MouseArea {
      id: padArea
      parent: padKey
      anchors.fill: parent
      z: -1
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: padKey.clicked()
      onEntered: if (padKey.tooltip)
                   TooltipService.show(padKey, padKey.tooltip, "bottom")
      onExited: if (padKey.tooltip)
                  TooltipService.hide(padKey)
    }
  }

  // One color filter key; the active one latches down
  component SwatchKey: PadKey {
    id: swatchKey
    property string familyKey
    property color swatch: root.keyFill
    property int introIndex: 0
    readonly property bool active: root.picker.familyKey === familyKey
    readonly property int count: familyKey === "" ? 1 : (root.picker.familyCounts[familyKey] || 0)
    width: Math.round(28 * root.s)
    height: width
    radius: Math.round(6 * root.s)
    fillColor: familyKey === "" ? root.kit.cream : solid(swatch)
    ringColor: root.kit.ringFor(fillColor)
    latched: active
    opacity: count > 0 || active ? 1 : 0.35
    scale: WallpaperPicker.introItem(root.intro, introIndex, root.introCount)
    onClicked: root.picker.setFamily(familyKey)

    NIcon {
      anchors.centerIn: parent
      visible: swatchKey.familyKey === "" || swatchKey.active
      icon: swatchKey.familyKey === "" ? "color-swatch" : "check"
      pointSize: Style.fontSizeS
      color: root.kit.readableOn(swatchKey.fillColor)
    }
  }

  // Die-cut sticker with an icon: ink outline, hard shadow, slight tilt
  component Sticker: Item {
    id: sticker
    property string text
    property string icon
    property color body: root.kit.cream
    property real maxWidth: 100000
    readonly property color textColor: root.kit.readableOn(body)
    property real tilt: 0
    implicitWidth: Math.min(maxWidth, stickerRow.implicitWidth + Style.marginM * 2)
    implicitHeight: stickerRow.implicitHeight + Style.marginS * 2
    width: implicitWidth
    height: implicitHeight
    rotation: tilt
    Rectangle {
      y: root.depth
      width: parent.width
      height: parent.height
      radius: root.kit.smallRadius
      color: root.kit.ink
    }
    Rectangle {
      anchors.fill: parent
      radius: root.kit.smallRadius
      color: sticker.body
      border.color: root.kit.ink
      border.width: root.kit.outline
    }
    Row {
      id: stickerRow
      anchors.centerIn: parent
      spacing: Style.marginS
      NIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: sticker.icon !== ""
        icon: sticker.icon
        pointSize: Style.fontSizeL
        color: sticker.textColor
      }
      NText {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, sticker.maxWidth - Style.marginM * 2 - (sticker.icon !== "" ? Style.fontSizeL * 1.5 + Style.marginS : 0))
        text: sticker.text
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightBold
        color: sticker.textColor
        elide: Text.ElideMiddle
      }
    }
  }

  // Tiny keycap legend for the keyboard hints
  component HintKey: Row {
    id: hintRow
    property string keyLabel
    property string hint
    spacing: Style.marginXS
    Keycap.Key {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(height, hintKeyLabel.implicitWidth + Style.marginS * 2)
      height: Math.round(22 * root.s)
      fillColor: root.kit.cream
      inkColor: root.kit.ink
      ringColor: root.kit.cream
      radius: Math.round(5 * root.s)
      outlineWidth: Math.max(1, root.kit.outline - 1)
      ringWidth: 0
      depth: Math.max(1, root.depth - 1)
      NText {
        id: hintKeyLabel
        anchors.centerIn: parent
        text: hintRow.keyLabel
        pointSize: Style.fontSizeXXS
        font.weight: Style.fontWeightBold
        color: root.kit.readableOn(root.kit.cream)
      }
    }
    NText {
      anchors.verticalCenter: parent.verticalCenter
      text: hintRow.hint
      pointSize: Style.fontSizeXS
      font.weight: Style.fontWeightMedium
      color: ShellColors.mOnSurfaceVariant
    }
  }
}
