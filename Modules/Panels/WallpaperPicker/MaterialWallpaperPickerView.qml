import QtQuick
import QtQuick.Layouts
import "../../../Helpers/WallpaperPicker.js" as WallpaperPicker

import qs.Commons
import qs.Services.UI
import qs.Widgets

// Material 3 wallpaper picker: a tonal search bar with the color swatches and a
// segmented sort control above a coverflow of rounded cards. Strips lean gently
// away from the selected card, which grows to full size with an extra-large
// radius, a primary outline and its file name on a tonal chip. State and
// actions live in WallpaperPickerPanel.qml (`picker`).
Item {
  id: root

  property var picker

  readonly property real s: Style.uiScaleRatio

  // Tonal palette, mixed from the shell colors (as in MaterialSessionMenuView)
  readonly property color container: Qt.tint(ShellColors.mSurface, Qt.alpha(ShellColors.mPrimary, 0.08))
  readonly property color containerHigh: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mOnSurface, 0.06))
  readonly property color primaryContainer: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mPrimary, 0.32))

  // Opening animation (WallpaperPicker.introBar, introItem): the toolbar grows from
  // a pill, then search, swatches, sort and count pop in one after another
  readonly property real intro: picker.intro
  readonly property var bar: WallpaperPicker.introBar(intro)
  readonly property int introCount: WallpaperPicker.families.length + 7

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

  // Toolbar ---------------------------------------------------------------

  Rectangle {
    id: toolbar
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: carousel.top
    anchors.bottomMargin: Math.round((28 - 24 * root.bar.lift) * root.s)
    readonly property real fullWidth: Math.min(parent.width - Style.margin2L * 2, toolbarRow.implicitWidth + Math.round(16 * root.s) * 2)
    width: Math.round(height + (fullWidth - height) * root.bar.grow)
    height: Math.round(64 * root.s)
    radius: height / 2
    color: root.container
    opacity: root.bar.opacity

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
        width: toolbar.fullWidth - Math.round(16 * root.s) * 2
        height: parent.height
        spacing: Math.round(16 * root.s)

        // Light or dark folder (Ctrl+L / Ctrl+D): a sun and moon segmented button
        Row {
          spacing: Math.round(2 * root.s)
          scale: WallpaperPicker.introItem(root.intro, 0, root.introCount)

          Repeater {
            model: root.modeOptions
            delegate: Rectangle {
              id: modeSegment
              required property var modelData
              required property int index
              readonly property bool active: root.picker.pickMode === modelData.key
              readonly property real r: height / 2
              readonly property real inner: Math.round(4 * root.s)
              width: Math.round(48 * root.s)
              height: Math.round(40 * root.s)
              topLeftRadius: index === 0 ? r : inner
              bottomLeftRadius: index === 0 ? r : inner
              topRightRadius: index === 1 ? r : inner
              bottomRightRadius: index === 1 ? r : inner
              color: active ? root.primaryContainer : modeArea.containsMouse ? Qt.tint(root.containerHigh, Qt.alpha(ShellColors.mOnSurface, 0.08)) : root.containerHigh

              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }

              NIcon {
                anchors.centerIn: parent
                icon: modeSegment.modelData.icon
                pointSize: Style.fontSizeL
                color: modeSegment.active ? ShellColors.mOnSurface : ShellColors.mOnSurfaceVariant
              }

              MouseArea {
                id: modeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picker.setPickMode(modeSegment.modelData.key)
                onEntered: TooltipService.show(modeSegment, modeSegment.modelData.label, "bottom")
                onExited: TooltipService.hide(modeSegment)
              }
            }
          }
        }

        // Search: typing anywhere goes here
        Rectangle {
          scale: WallpaperPicker.introItem(root.intro, 1, root.introCount)
          Layout.preferredWidth: Math.round(300 * root.s)
          Layout.preferredHeight: Math.round(44 * root.s)
          radius: height / 2
          color: root.containerHigh

          NIcon {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: Math.round(14 * root.s)
            anchors.verticalCenter: parent.verticalCenter
            icon: "search"
            pointSize: Style.fontSizeL
            color: ShellColors.mOnSurfaceVariant
          }

          NText {
            id: queryText
            anchors.left: searchIcon.right
            anchors.leftMargin: Math.round(10 * root.s)
            anchors.right: clearButton.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.picker.query || I18n.tr("wallpaper-picker.search")
            color: root.picker.query ? ShellColors.mOnSurface : ShellColors.mOnSurfaceVariant
            pointSize: Style.fontSizeM
            elide: Text.ElideLeft
          }

          SearchCaret {
            x: queryText.x + (root.picker.query ? Math.min(queryText.width, queryText.contentWidth) : 0)
            anchors.verticalCenter: parent.verticalCenter
            height: Math.round(20 * root.s)
            color: ShellColors.mPrimary
          }

          NIconButton {
            id: clearButton
            anchors.right: parent.right
            anchors.rightMargin: Math.round(4 * root.s)
            anchors.verticalCenter: parent.verticalCenter
            visible: root.picker.query !== ""
            width: visible ? implicitWidth : 0
            icon: "x"
            baseSize: Style.baseWidgetSize * 0.7
            onClicked: root.picker.clearQuery()
          }
        }

        // Color filters
        Row {
          spacing: Math.round(6 * root.s)

          Swatch {
            familyKey: ""
            introIndex: 2
            tooltip: I18n.tr("wallpaper-picker.all-colors")
          }

          Repeater {
            model: WallpaperPicker.families
            delegate: Swatch {
              required property var modelData
              required property int index
              introIndex: index + 3
              familyKey: modelData.key
              swatch: modelData.swatch
              tooltip: I18n.tr("wallpaper-picker.families." + modelData.key)
            }
          }
        }

        // Order: a segmented button
        Row {
          spacing: Math.round(2 * root.s)

          Repeater {
            model: root.sortOptions
            delegate: Rectangle {
              id: segment
              required property var modelData
              required property int index
              readonly property bool active: root.picker.sortBy === modelData.key
              readonly property real r: height / 2
              readonly property real inner: Math.round(4 * root.s)
              scale: WallpaperPicker.introItem(root.intro, WallpaperPicker.families.length + 3 + index, root.introCount)
              width: segmentRow.implicitWidth + Math.round(14 * root.s) * 2
              height: Math.round(40 * root.s)
              topLeftRadius: index === 0 ? r : inner
              bottomLeftRadius: index === 0 ? r : inner
              topRightRadius: index === root.sortOptions.length - 1 ? r : inner
              bottomRightRadius: index === root.sortOptions.length - 1 ? r : inner
              color: active ? root.primaryContainer : segmentArea.containsMouse ? Qt.tint(root.containerHigh, Qt.alpha(ShellColors.mOnSurface, 0.08)) : root.containerHigh

              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }

              Row {
                id: segmentRow
                anchors.centerIn: parent
                spacing: Math.round(6 * root.s)
                NIcon {
                  anchors.verticalCenter: parent.verticalCenter
                  icon: segment.modelData.icon
                  pointSize: Style.fontSizeM
                  color: segment.active ? ShellColors.mOnSurface : ShellColors.mOnSurfaceVariant
                }
                NText {
                  anchors.verticalCenter: parent.verticalCenter
                  text: segment.modelData.label
                  pointSize: Style.fontSizeS
                  font.weight: Style.fontWeightMedium
                  color: segment.active ? ShellColors.mOnSurface : ShellColors.mOnSurfaceVariant
                }
              }

              MouseArea {
                id: segmentArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picker.setSort(segment.modelData.key)
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
          color: ShellColors.mOnSurfaceVariant
        }
      }
    }
  }

  // Carousel --------------------------------------------------------------

  NWallpaperCarousel {
    id: carousel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    height: root.centerHeight
    entries: root.picker.entries
    currentIndex: root.picker.selectedIndex
    centerHeight: root.centerHeight
    centerWidth: Math.round(root.centerHeight * 0.72)
    stripHeight: root.stripHeight
    stripWidth: Math.round(root.stripHeight * 0.15)
    gap: Math.round(10 * root.s)
    skew: 0.06
    mirror: true
    card: materialCard
    intro: root.intro
    onCardClicked: index => root.picker.activate(index)
    onStepped: delta => root.picker.move(delta)
  }

  // Empty, loading and indexing states under the carousel
  NText {
    anchors.centerIn: carousel
    visible: root.picker.entries.length === 0
    text: root.picker.loading ? I18n.tr("wallpaper-picker.loading") : root.picker.totalCount === 0 ? I18n.tr("wallpaper-picker.empty", {
                                                                                                               "folder": root.picker.folder
                                                                                                             }) : I18n.tr("wallpaper-picker.no-match")
    pointSize: Style.fontSizeL
    color: ShellColors.mOnSurface
  }

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: carousel.bottom
    anchors.topMargin: Math.round(28 * root.s)
    visible: root.picker.indexing && root.picker.indexedCount > 0
    width: indexingText.implicitWidth + Math.round(16 * root.s) * 2
    height: Math.round(32 * root.s)
    radius: height / 2
    color: root.container

    NText {
      id: indexingText
      anchors.centerIn: parent
      text: I18n.tr("wallpaper-picker.indexing", {
                      "done": root.picker.indexedCount,
                      "total": root.picker.totalCount
                    })
      pointSize: Style.fontSizeXS
      color: ShellColors.mOnSurfaceVariant
    }
  }

  // Building blocks --------------------------------------------------------

  Component {
    id: materialCard

    Item {
      id: card
      property Item slot
      readonly property var entry: slot ? slot.entry : null
      readonly property real focusAmount: slot ? slot.focusAmount : 0
      readonly property real radius: Math.round((12 + 16 * focusAmount) * root.s)

      NWallpaperImage {
        anchors.fill: parent
        entry: card.entry
        sharp: card.slot ? card.slot.sharp : false
        radius: card.radius
        decodeHeight: carousel.centerHeight
        placeholderColor: root.containerHigh
      }

      // Strips sit back a little; hover brings them forward
      Rectangle {
        anchors.fill: parent
        radius: card.radius
        color: "black"
        opacity: (1 - card.focusAmount) * (card.slot && card.slot.hovered ? 0.05 : 0.28)

        Behavior on opacity {
          NumberAnimation {
            duration: Style.animationFast
          }
        }
      }

      // Selection outline
      Rectangle {
        anchors.fill: parent
        anchors.margins: -Math.round(4 * root.s)
        radius: card.radius + Math.round(4 * root.s)
        color: "transparent"
        border.width: Math.round(3 * root.s)
        border.color: ShellColors.mPrimary
        opacity: card.focusAmount
      }

      // Format badge
      Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Math.round((6 + 6 * card.focusAmount) * root.s)
        width: badgeText.implicitWidth + Math.round(10 * root.s)
        height: Math.round(20 * root.s)
        radius: height / 2
        visible: badgeText.text !== "" && width < card.width - Math.round(8 * root.s)
        color: Qt.alpha(ShellColors.mSurface, 0.85)

        NText {
          id: badgeText
          anchors.centerIn: parent
          text: WallpaperPicker.badge(card.entry ? card.entry.ext : "")
          pointSize: Style.fontSizeXXS
          font.weight: Style.fontWeightBold
          color: ShellColors.mOnSurface
        }
      }

      // File name of the selected card
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(40 * root.s)
        width: Math.min(card.width - Math.round(24 * root.s), titleText.implicitWidth + Math.round(16 * root.s) * 2)
        height: Math.round(36 * root.s)
        radius: height / 2
        color: root.primaryContainer
        opacity: Math.max(0, card.focusAmount * 2 - 1)
        visible: opacity > 0

        NText {
          id: titleText
          anchors.fill: parent
          anchors.leftMargin: Math.round(16 * root.s)
          anchors.rightMargin: Math.round(16 * root.s)
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: WallpaperPicker.title(card.entry)
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightMedium
          color: ShellColors.mOnSurface
          elide: Text.ElideMiddle
        }
      }
    }
  }

  // One color filter: a round swatch that becomes a ringed chip when active
  component Swatch: Item {
    id: swatchItem
    property string familyKey
    property color swatch: "transparent"
    property string tooltip
    property int introIndex: 0
    readonly property bool active: root.picker.familyKey === familyKey
    readonly property int count: familyKey === "" ? 1 : (root.picker.familyCounts[familyKey] || 0)
    width: Math.round(28 * root.s)
    height: width
    opacity: count > 0 || active ? 1 : 0.3
    scale: WallpaperPicker.introItem(root.intro, introIndex, root.introCount)

    Rectangle {
      anchors.centerIn: parent
      width: parent.width + (swatchItem.active ? Math.round(6 * root.s) : 0)
      height: width
      radius: width / 2
      color: "transparent"
      border.width: swatchItem.active ? Math.round(2 * root.s) : 0
      border.color: ShellColors.mPrimary

      Behavior on width {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutBack
        }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: parent.width - (swatchArea.containsMouse ? 0 : Math.round(4 * root.s))
      height: width
      radius: width / 2
      color: swatchItem.familyKey === "" ? root.containerHigh : swatchItem.swatch
      border.width: Math.max(1, Math.round(root.s))
      border.color: Qt.alpha(ShellColors.mOutline, 0.6)

      NIcon {
        anchors.centerIn: parent
        visible: swatchItem.familyKey === ""
        icon: "color-swatch"
        pointSize: Style.fontSizeS
        color: ShellColors.mOnSurfaceVariant
      }

      Behavior on width {
        NumberAnimation {
          duration: Style.animationFast
        }
      }
    }

    MouseArea {
      id: swatchArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.picker.setFamily(swatchItem.familyKey)
      onEntered: TooltipService.show(swatchItem, swatchItem.tooltip, "bottom")
      onExited: TooltipService.hide(swatchItem)
    }
  }

  // Blinking text cursor of the search field
  component SearchCaret: Rectangle {
    width: Math.max(1, Math.round(2 * root.s))
    radius: width / 2
    SequentialAnimation on opacity {
      loops: Animation.Infinite
      running: true
      NumberAnimation {
        to: 0
        duration: 500
        easing.type: Easing.InOutQuad
      }
      NumberAnimation {
        to: 1
        duration: 500
        easing.type: Easing.InOutQuad
      }
    }
  }
}
