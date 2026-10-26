import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Helpers/LauncherView.js" as LauncherView

import qs.Commons
import qs.Services.UI
import qs.Widgets

// Keycap app menu, laid out like a keyboard: a long search key on top, the
// modes as a function row, categories as a column of modifier keys, results
// as keycaps that lift when selected and sink when pressed, a tilted sticker
// headline, and a bottom row with the user and session keys. Every surface is
// opaque: ink outline, cream ring, fill and a hard shadow straight down.
// State lives in LauncherCore.
Item {
  id: root

  property var launcher

  readonly property real s: Style.uiScaleRatio
  readonly property var resultsView: swap.item
  readonly property var kit: KeycapKit

  readonly property real depth: kit.depth
  readonly property real gap: Style.marginS

  function solid(c) {
    return Qt.rgba(c.r, c.g, c.b, 1);
  }

  // Key fills (opaque, so the hard shadow never shows through)
  readonly property color keyFill: solid(Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mSurface, 0.35)))
  readonly property color keyText: kit.readableOn(keyFill)
  readonly property color creamText: kit.readableOn(kit.cream)
  readonly property color primaryFill: solid(ShellColors.mPrimary)
  readonly property color primaryText: kit.readableOn(primaryFill)
  readonly property color secondaryFill: solid(ShellColors.mSecondary)
  readonly property color secondaryText: kit.readableOn(secondaryFill)
  readonly property color errorFill: solid(ShellColors.mError)
  readonly property color errorText: kit.readableOn(errorFill)

  // Entries created while armed pop in with an overshoot
  property bool popArmed: true

  function armPop() {
    popArmed = true;
    disarmTimer.restart();
  }

  function focusSearch() {
    searchInput.forceActiveFocus();
  }
  function swapResults(direction, apply) {
    armPop();
    swap.swap(direction, apply);
  }
  function resetVisuals() {
    swap.resetVisuals();
  }
  function selectedRowTop(target) {
    const view = resultsView;
    const item = view && view.itemAtIndex ? view.itemAtIndex(launcher.selectedIndex) : null;
    return item ? item.mapToItem(target, 0, 0).y : null;
  }

  Timer {
    id: disarmTimer
    interval: 450
    running: true
    onTriggered: root.popArmed = false
  }

  Connections {
    target: root.launcher
    function onModeIdChanged() {
      root.armPop();
    }
    function onIsGridViewChanged() {
      root.armPop();
    }
    function onIsOpenChanged() {
      if (root.launcher.isOpen)
        root.armPop();
    }
  }

  Component.onCompleted: {
    if (launcher.isOpen)
      focusSearch();
  }

  // Building blocks --------------------------------------------------------

  // A clickable keycap. Children sit on the face and sink with it.
  component Key: NKeycap {
    id: key
    property bool interactive: true
    property string tooltip
    readonly property bool containsMouse: keyArea.containsMouse
    signal clicked
    fillColor: root.keyFill
    inkColor: root.kit.ink
    ringColor: root.kit.ringFor(fillColor)
    radius: Math.min(root.kit.smallRadius, height / 2)
    outlineWidth: root.kit.outline
    ringWidth: root.kit.ring
    depth: root.depth
    pressedDepth: root.kit.pressedDepth
    hoverLift: root.kit.hoverLift
    duration: root.kit.fast
    overshoot: root.kit.overshoot
    pressed: keyArea.pressed
    hovered: keyArea.containsMouse
    MouseArea {
      id: keyArea
      parent: key
      anchors.fill: parent
      z: -1
      enabled: key.interactive
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: key.clicked()
      onEntered: if (key.tooltip)
                   TooltipService.show(key, key.tooltip)
      onExited: if (key.tooltip)
                  TooltipService.hide()
    }
  }

  // Square glyph key
  component GlyphKey: Key {
    id: glyphKey
    property string icon
    property color glyphColor: root.keyText
    width: Math.round(40 * root.s)
    height: width
    NIcon {
      anchors.centerIn: parent
      icon: glyphKey.icon
      pointSize: Style.fontSizeL
      color: glyphKey.glyphColor
    }
  }

  // Die-cut sticker: cream body, ink outline, hard shadow, slight tilt
  component Sticker: Item {
    id: sticker
    property string text
    property color body: root.kit.cream
    property color textColor: root.kit.readableOn(body)
    property real tilt: 0
    property real pointSize: Style.fontSizeM
    implicitWidth: label.implicitWidth + Style.marginM * 2
    implicitHeight: label.implicitHeight + Style.marginXS * 2
    rotation: tilt
    Rectangle {
      y: root.kit.depth
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
    NText {
      id: label
      anchors.centerIn: parent
      text: sticker.text
      pointSize: sticker.pointSize
      font.weight: Style.fontWeightBold
      color: sticker.textColor
    }
  }

  // Tiny keycap legend for the keyboard hints in the footer
  component HintKey: Row {
    id: hintRow
    property string keyLabel
    property string hint
    spacing: Style.marginXS
    NKeycap {
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
        color: root.creamText
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

  // Layout -----------------------------------------------------------------

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    anchors.bottomMargin: Style.marginL + root.depth
    spacing: Style.marginM + root.depth

    // Search key + view toggle
    RowLayout {
      Layout.fillWidth: true
      spacing: root.gap

      Key {
        id: searchKey
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(52 * root.s)
        fillColor: root.kit.cream
        radius: root.kit.radius
        interactive: false
        latched: false
        hovered: searchInput.activeFocus

        // Mode sticker, stuck on with a tilt
        Rectangle {
          id: modeSticker
          x: Style.marginS
          anchors.verticalCenter: parent.verticalCenter
          width: Math.round(36 * root.s)
          height: width
          radius: Math.round(9 * root.s)
          rotation: -6
          color: root.launcher.modeId === "apps" ? root.primaryFill : root.secondaryFill
          border.color: root.kit.ink
          border.width: root.kit.outline
          NIcon {
            anchors.centerIn: parent
            icon: root.launcher.modeId === "apps" ? LauncherView.searchGlyph(root.launcher.searchText) : LauncherView.modeById(root.launcher.modeId).icon
            pointSize: Style.fontSizeL
            color: root.launcher.modeId === "apps" ? root.primaryText : root.secondaryText
          }
        }

        TextInput {
          id: searchInput
          anchors.left: modeSticker.right
          anchors.leftMargin: Style.marginM
          anchors.right: clearKey.visible ? clearKey.left : parent.right
          anchors.rightMargin: Style.marginM
          anchors.verticalCenter: parent.verticalCenter
          text: root.launcher.queryText
          color: root.creamText
          selectionColor: root.primaryFill
          selectedTextColor: root.primaryText
          font.family: Style.fontDefault
          font.pointSize: Style.fontSizeL * root.s
          font.weight: Style.fontWeightBold
          clip: true
          onTextEdited: root.launcher.setQuery(text)
          Keys.onPressed: event => root.launcher.handleKeyPress(event)
        }
        NText {
          anchors.left: searchInput.left
          anchors.right: searchInput.right
          anchors.verticalCenter: parent.verticalCenter
          visible: searchInput.text === ""
          text: root.launcher.modeId === "apps" ? I18n.tr("placeholders.search-launcher") : I18n.tr("launcher.view.search-in", {
                                                                                                      "mode": I18n.tr(LauncherView.modeById(root.launcher.modeId).labelKey)
                                                                                                    })
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightMedium
          color: Qt.alpha(root.creamText, 0.55)
          elide: Text.ElideRight
        }

        GlyphKey {
          id: clearKey
          visible: root.launcher.searchText !== ""
          anchors.right: parent.right
          anchors.rightMargin: Style.marginS
          anchors.verticalCenter: parent.verticalCenter
          width: Math.round(30 * root.s)
          depth: Math.max(1, root.depth - 1)
          icon: "x"
          tooltip: I18n.tr("launcher.view.clear")
          onClicked: {
            root.launcher.setQuery("");
            root.focusSearch();
          }
        }
      }

      Repeater {
        model: root.launcher.showLayoutToggle ? ["list", "grid"] : []
        GlyphKey {
          required property string modelData
          Layout.preferredWidth: Math.round(44 * root.s)
          Layout.preferredHeight: Math.round(52 * root.s)
          readonly property bool on: Settings.data.appLauncher.viewMode === modelData
          latched: on
          fillColor: on ? root.secondaryFill : root.keyFill
          glyphColor: on ? root.secondaryText : root.keyText
          icon: modelData === "list" ? "layout-list" : "layout-grid"
          onClicked: Settings.data.appLauncher.viewMode = modelData
        }
      }
    }

    // Function row: modes
    Row {
      id: modeRow
      Layout.fillWidth: true
      Layout.preferredHeight: Math.round(38 * root.s)
      spacing: root.gap
      Repeater {
        model: root.launcher.modes
        Key {
          id: modeKey
          required property var modelData
          required property int index
          readonly property bool on: root.launcher.modeId === modelData.id
          width: (modeRow.width - modeRow.spacing * (root.launcher.modes.length - 1)) / root.launcher.modes.length
          height: modeRow.height
          latched: on
          fillColor: on ? root.primaryFill : root.keyFill
          onClicked: root.launcher.setMode(modelData.id)
          Row {
            anchors.centerIn: parent
            spacing: Style.marginXS
            NIcon {
              anchors.verticalCenter: parent.verticalCenter
              icon: modeKey.modelData.icon
              pointSize: Style.fontSizeM
              color: modeKey.on ? root.primaryText : root.keyText
            }
            NText {
              anchors.verticalCenter: parent.verticalCenter
              text: I18n.tr(modeKey.modelData.labelKey)
              pointSize: Style.fontSizeS
              font.weight: Style.fontWeightBold
              color: modeKey.on ? root.primaryText : root.keyText
            }
          }
        }
      }
    }

    // Modifier column + results
    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: catColumn.shown ? Style.marginM : 0

      Item {
        id: catColumn
        readonly property bool shown: root.launcher.showProviderCategories
        Layout.preferredWidth: shown ? Math.round(172 * root.s) : 0
        Layout.fillHeight: true
        clip: true
        Behavior on Layout.preferredWidth {
          NumberAnimation {
            duration: root.kit.normal
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
          }
        }

        ListView {
          id: catList
          anchors.fill: parent
          anchors.topMargin: root.kit.hoverLift + 1
          width: Math.round(172 * root.s)
          clip: true
          spacing: Math.round(6 * root.s) + root.depth
          bottomMargin: root.depth + 1
          boundsBehavior: Flickable.StopAtBounds
          model: root.launcher.providerCategories
          currentIndex: root.launcher.selectedCategoryIndex
          onCurrentIndexChanged: if (currentIndex >= 0)
                                   positionViewAtIndex(currentIndex, ListView.Contain)
          delegate: Key {
            id: catKey
            required property string modelData
            required property int index
            readonly property bool on: index === root.launcher.selectedCategoryIndex
            width: Math.round(172 * root.s) - 2
            height: Math.round(36 * root.s)
            latched: on
            fillColor: on ? root.secondaryFill : root.keyFill
            onClicked: root.launcher.selectCategoryWithSlide(index)
            NIcon {
              id: catIcon
              x: Style.marginM
              anchors.verticalCenter: parent.verticalCenter
              icon: root.launcher.categoryIcon(catKey.modelData)
              pointSize: Style.fontSizeM
              color: catKey.on ? root.secondaryText : root.keyText
            }
            NText {
              anchors.left: catIcon.right
              anchors.leftMargin: Style.marginS
              anchors.right: parent.right
              anchors.rightMargin: Style.marginS
              anchors.verticalCenter: parent.verticalCenter
              text: root.launcher.categoryName(catKey.modelData)
              pointSize: Style.fontSizeS
              font.weight: Style.fontWeightBold
              color: catKey.on ? root.secondaryText : root.keyText
              elide: Text.ElideRight
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.marginM

        // Headline sticker + count sticker
        Row {
          Layout.fillWidth: true
          Layout.preferredHeight: headSticker.implicitHeight + root.depth
          Layout.leftMargin: Style.marginXS
          spacing: Style.marginS
          Sticker {
            id: headSticker
            text: root.launcher.headline.toUpperCase()
            pointSize: Style.fontSizeM
            tilt: LauncherView.tiltFor(root.launcher.headline, root.kit.tiltMax * 0.6)
          }
          Sticker {
            visible: root.launcher.statusText !== ""
            anchors.verticalCenter: headSticker.verticalCenter
            text: root.launcher.statusText
            body: root.primaryFill
            pointSize: Style.fontSizeXS
            tilt: -headSticker.tilt * 0.8
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          NSlideSwapView {
            id: swap
            anchors.fill: parent
            animationsEnabled: !root.launcher.animationsDisabled
            sourceComponent: root.launcher.isSingleView ? singleComponent : (root.launcher.isGridView ? gridComponent : listComponent)
          }

          // Empty state: a big tilted sticker
          Column {
            anchors.centerIn: parent
            spacing: Style.marginL
            visible: root.launcher.results.length === 0
            scale: visible ? 1 : 0.6
            Behavior on scale {
              NumberAnimation {
                duration: root.kit.normal
                easing.type: Easing.OutBack
                easing.overshoot: root.kit.popOvershoot
              }
            }
            Item {
              anchors.horizontalCenter: parent.horizontalCenter
              width: Math.round(84 * root.s)
              height: width + root.depth
              rotation: -8
              Rectangle {
                y: root.depth + 1
                width: parent.width
                height: width
                radius: Math.round(20 * root.s)
                color: root.kit.ink
              }
              Rectangle {
                width: parent.width
                height: width
                radius: Math.round(20 * root.s)
                color: root.kit.cream
                border.color: root.kit.ink
                border.width: root.kit.outline + 1
                NIcon {
                  anchors.centerIn: parent
                  icon: root.launcher.queryText !== "" ? "mood-empty" : LauncherView.modeById(root.launcher.modeId).icon
                  pointSize: Style.fontSizeXXXL * 1.4
                  color: root.creamText
                }
              }
            }
            NText {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.launcher.statusText
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: ShellColors.mOnSurface
            }
          }
        }
      }
    }

    // Bottom row: user, hints, session keys
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: Math.round(40 * root.s)
      spacing: Style.marginM

      Item {
        Layout.preferredWidth: Math.round(40 * root.s)
        Layout.preferredHeight: Layout.preferredWidth
        Rectangle {
          y: root.depth
          width: parent.width
          height: parent.height
          radius: width / 2
          color: root.kit.ink
        }
        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: root.kit.cream
          border.color: root.kit.ink
          border.width: root.kit.outline
          NImageRounded {
            anchors.fill: parent
            anchors.margins: root.kit.outline + 1
            radius: width / 2
            imagePath: root.launcher.avatarPath
            fallbackIcon: "person"
          }
        }
      }
      ColumnLayout {
        spacing: 0
        NText {
          text: root.launcher.userName
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightBold
          color: ShellColors.mOnSurface
        }
        NText {
          text: root.launcher.hostName
          pointSize: Style.fontSizeXS
          color: ShellColors.mOnSurfaceVariant
        }
      }

      Item {
        Layout.fillWidth: true
      }

      Row {
        spacing: Style.marginM
        HintKey {
          keyLabel: "↵"
          hint: I18n.tr("launcher.view.hint-open")
        }
        HintKey {
          visible: root.launcher.showProviderCategories
          keyLabel: "Tab"
          hint: I18n.tr("launcher.view.hint-category")
        }
        HintKey {
          keyLabel: "Ctrl Tab"
          hint: I18n.tr("launcher.view.hint-mode")
        }
      }

      Item {
        Layout.preferredWidth: Style.marginS
      }

      GlyphKey {
        icon: "settings"
        tooltip: I18n.tr("tooltips.open-settings")
        onClicked: root.launcher.openSettings()
      }
      GlyphKey {
        icon: "lock"
        tooltip: I18n.tr("common.lock")
        onClicked: root.launcher.lockSession()
      }
      GlyphKey {
        icon: "power"
        tooltip: I18n.tr("tooltips.session-menu")
        fillColor: root.errorFill
        glyphColor: root.errorText
        onClicked: root.launcher.openSessionMenu()
      }
    }
  }

  // Results ----------------------------------------------------------------

  Component {
    id: listComponent
    ListView {
      id: list
      clip: true
      spacing: root.gap + root.depth
      topMargin: root.kit.hoverLift + 2
      bottomMargin: root.depth + 2
      model: root.launcher.results
      currentIndex: root.launcher.selectedIndex
      cacheBuffer: height * 2
      boundsBehavior: Flickable.StopAtBounds
      interactive: !Settings.data.appLauncher.ignoreMouseInput
      readonly property var names: root.launcher.browsingApps ? root.launcher.results.map(r => r.name) : []
      onCurrentIndexChanged: {
        cancelFlick();
        if (currentIndex >= 0)
          positionViewAtIndex(currentIndex, ListView.Contain);
      }
      delegate: listDelegate
    }
  }

  Component {
    id: listDelegate
    Item {
      id: row
      required property var modelData
      required property int index
      readonly property var launcher: root.launcher
      readonly property bool selected: index === launcher.selectedIndex
      readonly property bool hero: index === 0 && launcher.showTopHit
      readonly property string letter: launcher.browsingApps ? LauncherView.sectionLetter(ListView.view.names, index) : ""
      readonly property real gutter: launcher.browsingApps ? Math.round(34 * root.s) : 0
      readonly property real iconSize: hero ? Math.round(52 * root.s) : launcher.badgeSize

      width: ListView.view.width
      height: hero ? Math.round(104 * root.s) : launcher.entryHeight

      // Pop in with an overshoot when the list is fresh
      scale: 1
      transformOrigin: Item.Left
      Component.onCompleted: {
        if (root.popArmed && root.kit.animated && index < 12) {
          scale = 0.82;
          opacity = 0;
          popAnim.start();
        }
      }
      SequentialAnimation {
        id: popAnim
        PauseAnimation {
          duration: LauncherView.popDelay(row.index, 22, 10)
        }
        ParallelAnimation {
          NumberAnimation {
            target: row
            property: "scale"
            to: 1
            duration: root.kit.normal
            easing.type: Easing.OutBack
            easing.overshoot: root.kit.popOvershoot
          }
          NumberAnimation {
            target: row
            property: "opacity"
            to: 1
            duration: root.kit.fast
          }
        }
      }

      // Section letter as a little cream key
      NKeycap {
        visible: row.letter !== ""
        width: Math.round(26 * root.s)
        height: width
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.depth / 2
        fillColor: root.kit.cream
        inkColor: root.kit.ink
        ringColor: root.kit.cream
        radius: Math.round(6 * root.s)
        outlineWidth: root.kit.outline
        ringWidth: 0
        depth: Math.max(1, root.depth - 1)
        rotation: LauncherView.tiltFor(row.letter, root.kit.tiltMax)
        NText {
          anchors.centerIn: parent
          text: row.letter
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightBold
          color: root.creamText
        }
      }

      Key {
        id: card
        x: row.gutter
        width: parent.width - row.gutter
        height: parent.height
        radius: row.hero ? root.kit.radius : Math.min(root.kit.radius, height / 3)
        interactive: !Settings.data.appLauncher.ignoreMouseInput
        hovered: row.selected || containsMouse
        fillColor: row.selected ? root.primaryFill : root.keyFill
        readonly property color ink: row.selected ? root.primaryText : root.keyText
        onContainsMouseChanged: if (containsMouse && !row.launcher.ignoreMouseHover)
                                  row.launcher.selectIndex(row.index)
        onClicked: row.launcher.activateIndex(row.index)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: row.hero ? Style.marginL : Style.marginM
          anchors.rightMargin: Style.marginM
          spacing: row.hero ? Style.marginL : Style.marginM

          // Icon sitting in a cream socket
          Rectangle {
            Layout.preferredWidth: row.iconSize + Style.marginXS * 2
            Layout.preferredHeight: Layout.preferredWidth
            visible: !row.modelData.hideIcon
            radius: Math.round(9 * root.s)
            color: root.kit.cream
            border.color: root.kit.ink
            border.width: Math.max(1, root.kit.outline - 1)
            rotation: row.selected ? -4 : 0
            Behavior on rotation {
              NumberAnimation {
                duration: root.kit.normal
                easing.type: Easing.OutBack
                easing.overshoot: root.kit.overshoot
              }
            }
            LauncherEntryIcon {
              anchors.fill: parent
              anchors.margins: Style.marginXS
              entry: row.modelData
              radius: Math.round(6 * root.s)
              glyphSize: row.hero ? Style.fontSizeXXL : Style.fontSizeL
              glyphColor: root.creamText
              letterColor: root.creamText
              swatchBorder: root.kit.ink
              badgeColor: root.primaryFill
              badgeTextColor: root.primaryText
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Sticker {
              visible: row.hero
              text: I18n.tr("launcher.view.top-hit").toUpperCase()
              pointSize: Style.fontSizeXXS
              tilt: -3
              Layout.bottomMargin: Style.marginXS + root.depth
            }
            NText {
              Layout.fillWidth: true
              text: row.modelData.name || ""
              pointSize: row.hero ? Style.fontSizeXL : Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: card.ink
              elide: Text.ElideRight
              maximumLineCount: 1
            }
            NText {
              Layout.fillWidth: true
              text: row.modelData.description || ""
              visible: text !== "" && !row.launcher.isCompactDensity
              pointSize: Style.fontSizeS
              font.weight: Style.fontWeightMedium
              color: Qt.alpha(card.ink, 0.75)
              elide: Text.ElideRight
              maximumLineCount: 1
            }
          }

          NIcon {
            visible: row.launcher.isPinned(row.modelData) && !row.selected
            icon: "pinned"
            pointSize: Style.fontSizeM
            color: card.ink
            rotation: 20
          }

          Repeater {
            model: row.selected ? row.launcher.itemActions(row.modelData) : []
            GlyphKey {
              required property var modelData
              width: Math.round(30 * root.s)
              depth: Math.max(1, root.depth - 1)
              fillColor: root.kit.cream
              glyphColor: root.creamText
              icon: modelData.icon
              tooltip: modelData.tooltip || ""
              onClicked: if (modelData.action)
                           modelData.action()
            }
          }

          // Enter key on the selected row
          NKeycap {
            visible: row.selected
            Layout.preferredWidth: Math.round((row.hero ? 64 : 34) * root.s)
            Layout.preferredHeight: Math.round(30 * root.s)
            Layout.bottomMargin: root.depth
            fillColor: root.kit.cream
            inkColor: root.kit.ink
            ringColor: root.kit.cream
            radius: Math.round(7 * root.s)
            outlineWidth: root.kit.outline
            ringWidth: 0
            depth: Math.max(1, root.depth - 1)
            Row {
              anchors.centerIn: parent
              spacing: Style.marginXXS
              NIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: "corner-down-left"
                pointSize: Style.fontSizeM
                color: root.creamText
              }
              NText {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.hero
                text: I18n.tr("launcher.view.open")
                pointSize: Style.fontSizeXS
                font.weight: Style.fontWeightBold
                color: root.creamText
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: gridComponent
    GridView {
      id: grid
      clip: true
      topMargin: root.kit.hoverLift + 2
      readonly property var cell: LauncherView.gridCell(width, root.launcher.targetGridColumns, root.launcher.currentProvider && root.launcher.currentProvider.preferredGridCellRatio ? root.launcher.currentProvider.preferredGridCellRatio : 1)
      cellWidth: cell.width
      cellHeight: cell.height
      model: root.launcher.results
      cacheBuffer: height * 2
      boundsBehavior: Flickable.StopAtBounds
      interactive: !Settings.data.appLauncher.ignoreMouseInput
      keyNavigationEnabled: false
      Connections {
        target: root.launcher
        function onSelectedIndexChanged() {
          if (root.launcher.selectedIndex >= 0)
            Qt.callLater(() => {
              grid.cancelFlick();
              grid.positionViewAtIndex(root.launcher.selectedIndex, GridView.Contain);
            });
        }
      }
      delegate: Item {
        id: tile
        required property var modelData
        required property int index
        readonly property bool selected: index === root.launcher.selectedIndex
        width: grid.cellWidth
        height: grid.cellHeight

        Component.onCompleted: {
          if (root.popArmed && root.kit.animated && index < 30) {
            tileKey.scale = 0.6;
            tileKey.opacity = 0;
            tilePop.start();
          }
        }
        SequentialAnimation {
          id: tilePop
          PauseAnimation {
            duration: LauncherView.popDelay(tile.index, 14, 20)
          }
          ParallelAnimation {
            NumberAnimation {
              target: tileKey
              property: "scale"
              to: 1
              duration: root.kit.normal
              easing.type: Easing.OutBack
              easing.overshoot: root.kit.popOvershoot
            }
            NumberAnimation {
              target: tileKey
              property: "opacity"
              to: 1
              duration: root.kit.fast
            }
          }
        }

        Key {
          id: tileKey
          x: Math.round(4 * root.s)
          y: Math.round(2 * root.s)
          width: parent.width - Math.round(8 * root.s)
          height: parent.height - Math.round(8 * root.s) - root.depth
          radius: Math.round(10 * root.s)
          interactive: !Settings.data.appLauncher.ignoreMouseInput
          hovered: tile.selected || containsMouse
          fillColor: tile.selected ? root.primaryFill : root.keyFill
          readonly property color ink: tile.selected ? root.primaryText : root.keyText
          onContainsMouseChanged: if (containsMouse && !root.launcher.ignoreMouseHover)
                                    root.launcher.selectIndex(tile.index)
          onClicked: root.launcher.activateIndex(tile.index)

          // Legend in the corner, like a real keycap
          NText {
            visible: !tile.modelData.displayString
            x: Style.marginS
            y: Style.marginXS
            text: LauncherView.initialOf(tile.modelData.name)
            pointSize: Style.fontSizeXS
            font.weight: Style.fontWeightBold
            color: Qt.alpha(tileKey.ink, 0.7)
          }

          LauncherEntryIcon {
            id: tileIcon
            readonly property real size: Math.round(Math.min(tileKey.width, tileKey.height) * (tile.modelData.hideLabel ? 0.6 : (tile.modelData.displayString ? 0.52 : 0.46)))
            width: size
            height: size
            anchors.horizontalCenter: parent.horizontalCenter
            y: tile.modelData.hideLabel ? (parent.height - height) / 2 : parent.height * 0.16
            entry: tile.modelData
            radius: Math.round(6 * root.s)
            glyphSize: Style.fontSizeXXL
            glyphColor: tileKey.ink
            letterColor: tileKey.ink
            swatchBorder: root.kit.ink
            rotation: tile.selected ? -6 : 0
            Behavior on rotation {
              NumberAnimation {
                duration: root.kit.normal
                easing.type: Easing.OutBack
                easing.overshoot: root.kit.overshoot
              }
            }
          }

          NText {
            visible: !tile.modelData.hideLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Style.marginXS
            anchors.top: tileIcon.bottom
            anchors.topMargin: Style.marginXS
            horizontalAlignment: Text.AlignHCenter
            text: tile.modelData.name || ""
            pointSize: Style.fontSizeXS
            font.weight: Style.fontWeightBold
            color: tileKey.ink
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          Row {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.marginXS
            visible: tile.selected
            Repeater {
              model: tile.selected ? root.launcher.itemActions(tile.modelData) : []
              GlyphKey {
                required property var modelData
                width: Math.round(24 * root.s)
                depth: Math.max(1, root.depth - 1)
                fillColor: root.kit.cream
                glyphColor: root.creamText
                icon: modelData.icon
                tooltip: modelData.tooltip || ""
                onClicked: if (modelData.action)
                             modelData.action()
              }
            }
          }
          NIcon {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.marginS
            visible: !tile.selected && root.launcher.isPinned(tile.modelData)
            icon: "pinned"
            pointSize: Style.fontSizeS
            color: tileKey.ink
            rotation: 20
          }
        }
      }
    }
  }

  Component {
    id: singleComponent
    Item {
      Key {
        anchors.fill: parent
        anchors.bottomMargin: root.depth
        radius: root.kit.radius
        interactive: false
        fillColor: root.kit.cream
        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginXL
          spacing: Style.marginM
          NText {
            Layout.fillWidth: true
            text: root.launcher.results.length > 0 ? root.launcher.results[0].name : ""
            pointSize: Style.fontSizeXXL
            font.weight: Style.fontWeightBold
            color: root.creamText
            wrapMode: Text.Wrap
          }
          NScrollView {
            id: singleScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalPolicy: ScrollBar.AlwaysOff
            reserveScrollbarSpace: false
            NText {
              width: singleScroll.availableWidth
              text: root.launcher.results.length > 0 ? (root.launcher.results[0].description || "") : ""
              pointSize: Style.fontSizeM
              color: root.creamText
              wrapMode: Text.Wrap
              markdownTextEnabled: true
            }
          }
        }
      }
    }
  }
}
