import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/LauncherView.js" as LauncherView

import qs.Commons
import qs.Services.UI
import qs.Widgets

// Material 3 Expressive app menu: pill search bar, a connected button group
// of modes, a navigation drawer of categories, a headline over a segmented
// list (the selected row morphs into a pill) or a grid of shape tiles, and a
// footer with the user and session actions. State lives in LauncherCore.
Item {
  id: root

  property var launcher

  readonly property real s: Style.uiScaleRatio
  readonly property var resultsView: swap.item

  // Tonal palette, mixed from the shell colors
  readonly property color containerLow: Qt.tint(ShellColors.mSurface, Qt.alpha(ShellColors.mPrimary, 0.05))
  readonly property color container: Qt.tint(ShellColors.mSurface, Qt.alpha(ShellColors.mPrimary, 0.12))
  readonly property color containerHigh: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mOnSurface, 0.06))
  readonly property color primaryContainer: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mPrimary, 0.32))
  readonly property color secondaryContainer: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mSecondary, 0.28))
  readonly property color errorContainer: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mError, 0.22))

  readonly property int spring: Style.animationNormal
  readonly property real overshoot: 1.3

  function focusSearch() {
    searchInput.forceActiveFocus();
  }
  function swapResults(direction, apply) {
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

  Component.onCompleted: {
    if (launcher.isOpen)
      focusSearch();
  }

  // Shared bits ------------------------------------------------------------

  component StateLayer: Rectangle {
    property bool hovered: false
    property bool pressed: false
    property color tone: ShellColors.mOnSurface
    anchors.fill: parent
    color: Qt.alpha(tone, pressed ? 0.12 : (hovered ? 0.08 : 0))
    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
  }

  // Round icon button with a state layer
  component IconButton: Item {
    id: btn
    property string icon
    property string tooltip
    property color fill: "transparent"
    property color iconColor: ShellColors.mOnSurfaceVariant
    property real size: Math.round(40 * root.s)
    signal clicked
    implicitWidth: size
    implicitHeight: size
    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: btn.fill
      clip: true
      StateLayer {
        radius: parent.radius
        hovered: btnArea.containsMouse
        pressed: btnArea.pressed
        tone: btn.iconColor
      }
    }
    NIcon {
      anchors.centerIn: parent
      icon: btn.icon
      pointSize: Style.fontSizeL
      color: btn.iconColor
    }
    MouseArea {
      id: btnArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: btn.clicked()
      onEntered: if (btn.tooltip)
                   TooltipService.show(btn, btn.tooltip)
      onExited: TooltipService.hide()
    }
  }

  // One segment of a connected button group; the selected one turns into a pill
  component Segment: Rectangle {
    id: seg
    property int index
    property int count
    property bool selected
    property string icon
    property string label
    property color selectedFill: ShellColors.mPrimary
    property color selectedText: ShellColors.mOnPrimary
    property color restFill: root.containerHigh
    property color restText: ShellColors.mOnSurface
    signal clicked
    readonly property var radii: LauncherView.groupRadii(index, count, height, height / 2, Math.round(8 * root.s), selected || segArea.pressed, false)
    color: selected ? selectedFill : restFill
    topLeftRadius: radii.tl
    topRightRadius: radii.tr
    bottomLeftRadius: radii.bl
    bottomRightRadius: radii.br
    clip: true
    Behavior on topLeftRadius {
      NumberAnimation {
        duration: root.spring
        easing.type: Easing.OutBack
        easing.overshoot: root.overshoot
      }
    }
    Behavior on topRightRadius {
      NumberAnimation {
        duration: root.spring
        easing.type: Easing.OutBack
        easing.overshoot: root.overshoot
      }
    }
    Behavior on bottomLeftRadius {
      NumberAnimation {
        duration: root.spring
        easing.type: Easing.OutBack
        easing.overshoot: root.overshoot
      }
    }
    Behavior on bottomRightRadius {
      NumberAnimation {
        duration: root.spring
        easing.type: Easing.OutBack
        easing.overshoot: root.overshoot
      }
    }
    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
    StateLayer {
      topLeftRadius: seg.topLeftRadius
      topRightRadius: seg.topRightRadius
      bottomLeftRadius: seg.bottomLeftRadius
      bottomRightRadius: seg.bottomRightRadius
      hovered: segArea.containsMouse
      pressed: segArea.pressed
      tone: seg.selected ? seg.selectedText : seg.restText
    }
    Row {
      anchors.centerIn: parent
      spacing: Style.marginXS
      NIcon {
        anchors.verticalCenter: parent.verticalCenter
        icon: seg.icon
        visible: seg.icon !== ""
        pointSize: Style.fontSizeL
        color: seg.selected ? seg.selectedText : seg.restText
      }
      NText {
        anchors.verticalCenter: parent.verticalCenter
        visible: seg.label !== ""
        text: seg.label
        pointSize: Style.fontSizeM
        font.weight: seg.selected ? Style.fontWeightBold : Style.fontWeightMedium
        color: seg.selected ? seg.selectedText : seg.restText
      }
    }
    MouseArea {
      id: segArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: seg.clicked()
    }
  }

  // Layout -----------------------------------------------------------------

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    // Search bar
    Rectangle {
      id: searchBar
      Layout.fillWidth: true
      Layout.preferredHeight: Math.round(56 * root.s)
      radius: height / 2
      color: root.containerHigh
      border.width: searchInput.activeFocus ? Math.max(1, Math.round(2 * root.s)) : 0
      border.color: ShellColors.mPrimary

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.marginS
        anchors.rightMargin: Style.marginS
        spacing: Style.marginS

        Rectangle {
          Layout.preferredWidth: Math.round(40 * root.s)
          Layout.preferredHeight: Layout.preferredWidth
          radius: width / 2
          color: root.launcher.modeId === "apps" ? "transparent" : ShellColors.mPrimary
          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }
          NIcon {
            anchors.centerIn: parent
            icon: root.launcher.modeId === "apps" ? LauncherView.searchGlyph(root.launcher.searchText) : LauncherView.modeById(root.launcher.modeId).icon
            pointSize: Style.fontSizeXL
            color: root.launcher.modeId === "apps" ? ShellColors.mOnSurfaceVariant : ShellColors.mOnPrimary
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          TextInput {
            id: searchInput
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.launcher.queryText
            color: ShellColors.mOnSurface
            selectionColor: Qt.alpha(ShellColors.mPrimary, 0.35)
            selectedTextColor: ShellColors.mOnSurface
            font.family: Style.fontDefault
            font.pointSize: Style.fontSizeL * root.s
            clip: true
            onTextEdited: root.launcher.setQuery(text)
            Keys.onPressed: event => root.launcher.handleKeyPress(event)
          }
          NText {
            anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text === ""
            text: root.launcher.modeId === "apps" ? I18n.tr("placeholders.search-launcher") : I18n.tr("launcher.view.search-in", {
                                                                                                        "mode": I18n.tr(LauncherView.modeById(root.launcher.modeId).labelKey)
                                                                                                      })
            pointSize: Style.fontSizeL
            color: ShellColors.mOnSurfaceVariant
            elide: Text.ElideRight
            width: parent.width
          }
        }

        IconButton {
          visible: root.launcher.searchText !== ""
          icon: "x"
          tooltip: I18n.tr("launcher.view.clear")
          onClicked: {
            root.launcher.setQuery("");
            root.focusSearch();
          }
        }
      }
    }

    // Modes: connected button group
    Row {
      id: modeRow
      Layout.fillWidth: true
      Layout.preferredHeight: Math.round(40 * root.s)
      spacing: Math.round(2 * root.s)
      Repeater {
        model: root.launcher.modes
        Segment {
          required property var modelData
          required property int index
          width: (modeRow.width - modeRow.spacing * (root.launcher.modes.length - 1)) / root.launcher.modes.length
          height: modeRow.height
          count: root.launcher.modes.length
          selected: root.launcher.modeId === modelData.id
          icon: modelData.icon
          label: I18n.tr(modelData.labelKey)
          onClicked: root.launcher.setMode(modelData.id)
        }
      }
    }

    // Drawer + content
    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: drawer.shown ? Style.marginM : 0

      // Navigation drawer of categories
      Rectangle {
        id: drawer
        readonly property bool shown: root.launcher.showProviderCategories
        Layout.preferredWidth: shown ? Math.round(184 * root.s) : 0
        Layout.fillHeight: true
        radius: Math.round(28 * root.s)
        color: root.containerLow
        clip: true
        opacity: shown ? 1 : 0
        Behavior on Layout.preferredWidth {
          NumberAnimation {
            duration: root.spring
            easing.type: Easing.OutBack
            easing.overshoot: 1.0
          }
        }
        Behavior on opacity {
          NumberAnimation {
            duration: Style.animationFast
          }
        }

        ListView {
          id: drawerList
          anchors.fill: parent
          anchors.margins: Style.marginS
          width: Math.round(184 * root.s) - 2 * Style.marginS
          clip: true
          spacing: Math.round(2 * root.s)
          boundsBehavior: Flickable.StopAtBounds
          model: root.launcher.providerCategories
          currentIndex: root.launcher.selectedCategoryIndex
          onCurrentIndexChanged: if (currentIndex >= 0)
                                   positionViewAtIndex(currentIndex, ListView.Contain)
          delegate: Rectangle {
            id: navItem
            required property string modelData
            required property int index
            readonly property bool selected: index === root.launcher.selectedCategoryIndex
            width: drawerList.width
            height: Math.round(44 * root.s)
            radius: height / 2
            color: selected ? root.secondaryContainer : "transparent"
            clip: true
            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }
            StateLayer {
              radius: parent.radius
              hovered: navArea.containsMouse
              pressed: navArea.pressed
            }
            Row {
              anchors.left: parent.left
              anchors.leftMargin: Style.marginM
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.marginM
              NIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: root.launcher.categoryIcon(navItem.modelData)
                pointSize: Style.fontSizeL
                color: navItem.selected ? ShellColors.mOnSurface : ShellColors.mOnSurfaceVariant
                scale: navItem.selected ? 1.12 : 1
                Behavior on scale {
                  NumberAnimation {
                    duration: root.spring
                    easing.type: Easing.OutBack
                    easing.overshoot: 2
                  }
                }
              }
              NText {
                anchors.verticalCenter: parent.verticalCenter
                width: navItem.width - Style.marginM * 3 - Style.fontSizeL * 1.5 * root.s
                text: root.launcher.categoryName(navItem.modelData)
                pointSize: Style.fontSizeM
                font.weight: navItem.selected ? Style.fontWeightBold : Style.fontWeightMedium
                color: navItem.selected ? ShellColors.mOnSurface : ShellColors.mOnSurfaceVariant
                elide: Text.ElideRight
              }
            }
            MouseArea {
              id: navArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.launcher.selectCategoryWithSlide(navItem.index)
            }
          }
        }
      }

      // Content
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.marginS

        RowLayout {
          Layout.fillWidth: true
          Layout.leftMargin: Style.marginXS
          spacing: Style.marginS

          NText {
            Layout.maximumWidth: parent.width * 0.6
            text: root.launcher.headline
            pointSize: Style.fontSizeXXL
            font.weight: Style.fontWeightRegular
            color: ShellColors.mOnSurface
            elide: Text.ElideRight
          }

          // Result count chip
          Rectangle {
            visible: root.launcher.statusText !== ""
            Layout.preferredHeight: Math.round(24 * root.s)
            Layout.preferredWidth: countLabel.implicitWidth + Style.marginM * 2
            radius: height / 2
            color: root.secondaryContainer
            NText {
              id: countLabel
              anchors.centerIn: parent
              text: root.launcher.statusText
              pointSize: Style.fontSizeXS
              font.weight: Style.fontWeightMedium
              color: ShellColors.mOnSurface
            }
          }

          Item {
            Layout.fillWidth: true
          }

          // View toggle: two-segment connected group
          Row {
            visible: root.launcher.showLayoutToggle
            spacing: Math.round(2 * root.s)
            Repeater {
              model: [
                {
                  "mode": "list",
                  "icon": "layout-list"
                },
                {
                  "mode": "grid",
                  "icon": "layout-grid"
                }
              ]
              Segment {
                required property var modelData
                required property int index
                width: Math.round(44 * root.s)
                height: Math.round(34 * root.s)
                count: 2
                selected: Settings.data.appLauncher.viewMode === modelData.mode
                icon: modelData.icon
                label: ""
                selectedFill: root.secondaryContainer
                selectedText: ShellColors.mOnSurface
                restFill: root.containerLow
                onClicked: Settings.data.appLauncher.viewMode = modelData.mode
              }
            }
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

          // Empty state: a big tonal shape that springs in
          Column {
            anchors.centerIn: parent
            spacing: Style.marginL
            visible: root.launcher.results.length === 0
            scale: visible ? 1 : 0.7
            Behavior on scale {
              NumberAnimation {
                duration: root.spring
                easing.type: Easing.OutBack
                easing.overshoot: 1.6
              }
            }
            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: Math.round(96 * root.s)
              height: width
              radius: Math.round(32 * root.s)
              rotation: 12
              color: root.primaryContainer
              NIcon {
                anchors.centerIn: parent
                rotation: -12
                icon: root.launcher.queryText !== "" ? "mood-empty" : LauncherView.modeById(root.launcher.modeId).icon
                pointSize: Style.fontSizeXXXL * 1.4
                color: ShellColors.mOnSurface
              }
            }
            NText {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.launcher.statusText
              pointSize: Style.fontSizeL
              color: ShellColors.mOnSurfaceVariant
            }
          }
        }
      }
    }

    // Footer: user and session actions
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: Math.round(44 * root.s)
      spacing: Style.marginM

      NImageRounded {
        Layout.preferredWidth: Math.round(40 * root.s)
        Layout.preferredHeight: Layout.preferredWidth
        radius: width / 2
        imagePath: root.launcher.avatarPath
        fallbackIcon: "person"
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
          pointSize: Style.fontSizeS
          color: ShellColors.mOnSurfaceVariant
        }
      }
      Item {
        Layout.fillWidth: true
      }
      Row {
        spacing: Math.round(2 * root.s)
        Repeater {
          model: [
            {
              "icon": "settings",
              "tip": "tooltips.open-settings",
              "danger": false
            },
            {
              "icon": "lock",
              "tip": "common.lock",
              "danger": false
            },
            {
              "icon": "power",
              "tip": "tooltips.session-menu",
              "danger": true
            }
          ]
          Segment {
            required property var modelData
            required property int index
            width: Math.round(52 * root.s)
            height: Math.round(40 * root.s)
            count: 3
            selected: false
            icon: modelData.icon
            label: ""
            restFill: modelData.danger ? root.errorContainer : root.containerHigh
            restText: modelData.danger ? ShellColors.mError : ShellColors.mOnSurface
            onClicked: {
              if (index === 0)
                root.launcher.openSettings();
              else if (index === 1)
                root.launcher.lockSession();
              else
                root.launcher.openSessionMenu();
            }
          }
        }
      }
    }
  }

  // Results ----------------------------------------------------------------

  Component {
    id: listComponent
    ListView {
      id: list
      clip: true
      spacing: Math.round(2 * root.s)
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
      readonly property real gutter: launcher.browsingApps ? Math.round(32 * root.s) : 0
      readonly property int count: ListView.view ? ListView.view.count : 1
      readonly property real iconSize: hero ? Math.round(56 * root.s) : launcher.badgeSize

      width: ListView.view.width
      height: hero ? Math.round(116 * root.s) : launcher.entryHeight

      NText {
        visible: row.letter !== ""
        width: row.gutter
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: row.letter
        pointSize: Style.fontSizeXL
        font.weight: Style.fontWeightBold
        color: ShellColors.mPrimary
      }

      Rectangle {
        id: card
        x: row.gutter
        width: parent.width - row.gutter
        height: parent.height
        readonly property real outer: Math.round((row.hero ? 28 : 20) * root.s)
        readonly property var radii: row.hero ? ({
                                                   "tl": outer,
                                                   "tr": outer,
                                                   "bl": outer,
                                                   "br": outer
                                                 }) : LauncherView.groupRadii(row.index, row.count, height, outer, Math.round(6 * root.s), row.selected, true)
        topLeftRadius: radii.tl
        topRightRadius: radii.tr
        bottomLeftRadius: radii.bl
        bottomRightRadius: radii.br
        color: row.selected ? root.primaryContainer : root.container
        clip: true
        Behavior on topLeftRadius {
          NumberAnimation {
            duration: root.spring
            easing.type: Easing.OutBack
            easing.overshoot: root.overshoot
          }
        }
        Behavior on topRightRadius {
          NumberAnimation {
            duration: root.spring
            easing.type: Easing.OutBack
            easing.overshoot: root.overshoot
          }
        }
        Behavior on bottomLeftRadius {
          NumberAnimation {
            duration: root.spring
            easing.type: Easing.OutBack
            easing.overshoot: root.overshoot
          }
        }
        Behavior on bottomRightRadius {
          NumberAnimation {
            duration: root.spring
            easing.type: Easing.OutBack
            easing.overshoot: root.overshoot
          }
        }
        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }

        StateLayer {
          topLeftRadius: card.topLeftRadius
          topRightRadius: card.topRightRadius
          bottomLeftRadius: card.bottomLeftRadius
          bottomRightRadius: card.bottomRightRadius
          hovered: rowArea.containsMouse && !row.selected
          pressed: rowArea.pressed
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: row.hero ? Style.marginL : Style.marginM
          anchors.rightMargin: Style.marginM
          spacing: row.hero ? Style.marginL : Style.marginM

          // Icon in a tonal circle (glyphs) or bare (app icons, images)
          Rectangle {
            Layout.preferredWidth: row.iconSize
            Layout.preferredHeight: row.iconSize
            visible: !row.modelData.hideIcon
            radius: icon.kind === "app" || icon.kind === "image" ? Math.round(12 * root.s) : width / 2
            color: icon.kind === "glyph" || icon.kind === "letter" ? (row.selected ? ShellColors.mPrimary : root.secondaryContainer) : "transparent"
            scale: row.selected && !row.hero ? 1.08 : 1
            Behavior on scale {
              NumberAnimation {
                duration: root.spring
                easing.type: Easing.OutBack
                easing.overshoot: 2
              }
            }
            LauncherEntryIcon {
              id: icon
              anchors.fill: parent
              anchors.margins: kind === "app" ? 0 : (kind === "glyph" || kind === "letter" ? 0 : 0)
              entry: row.modelData
              radius: Math.round(12 * root.s)
              glyphSize: row.hero ? Style.fontSizeXXL : Style.fontSizeL
              glyphColor: row.selected ? ShellColors.mOnPrimary : ShellColors.mOnSurface
              letterColor: kind === "letter" && row.selected ? ShellColors.mOnPrimary : ShellColors.mOnSurface
              badgeColor: ShellColors.mPrimary
              badgeTextColor: ShellColors.mOnPrimary
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: row.hero ? Style.marginXXS : 0
            NText {
              Layout.fillWidth: true
              visible: row.hero
              text: I18n.tr("launcher.view.top-hit")
              pointSize: Style.fontSizeXS
              font.weight: Style.fontWeightBold
              font.capitalization: Font.AllUppercase
              font.letterSpacing: 1
              color: ShellColors.mPrimary
            }
            NText {
              Layout.fillWidth: true
              text: row.modelData.name || ""
              pointSize: row.hero ? Style.fontSizeXL : Style.fontSizeL
              font.weight: row.hero ? Style.fontWeightBold : Style.fontWeightMedium
              color: ShellColors.mOnSurface
              elide: Text.ElideRight
              maximumLineCount: 1
            }
            NText {
              Layout.fillWidth: true
              text: row.modelData.description || ""
              visible: text !== "" && !row.launcher.isCompactDensity
              pointSize: Style.fontSizeS
              color: ShellColors.mOnSurfaceVariant
              elide: Text.ElideRight
              maximumLineCount: row.hero ? 2 : 1
              wrapMode: row.hero ? Text.Wrap : Text.NoWrap
            }
          }

          NIcon {
            visible: row.launcher.isPinned(row.modelData) && !row.selected
            icon: "pinned"
            pointSize: Style.fontSizeM
            color: ShellColors.mPrimary
          }

          Repeater {
            model: row.selected ? row.launcher.itemActions(row.modelData) : []
            IconButton {
              required property var modelData
              icon: modelData.icon
              tooltip: modelData.tooltip || ""
              fill: Qt.alpha(ShellColors.mOnSurface, 0.06)
              iconColor: ShellColors.mOnSurface
              size: Math.round(36 * root.s)
              onClicked: if (modelData.action)
                           modelData.action()
            }
          }

          // Filled "Open" button on the top hit
          Rectangle {
            visible: row.hero
            Layout.preferredHeight: Math.round(40 * root.s)
            Layout.preferredWidth: openLabel.implicitWidth + Style.marginL * 2
            radius: height / 2
            color: ShellColors.mPrimary
            NText {
              id: openLabel
              anchors.centerIn: parent
              text: I18n.tr("launcher.view.open")
              pointSize: Style.fontSizeM
              font.weight: Style.fontWeightBold
              color: ShellColors.mOnPrimary
            }
          }
        }
      }

      MouseArea {
        id: rowArea
        anchors.fill: card
        z: -1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !Settings.data.appLauncher.ignoreMouseInput
        onEntered: if (!row.launcher.ignoreMouseHover)
                     row.launcher.selectIndex(row.index)
        onClicked: row.launcher.activateIndex(row.index)
      }
    }
  }

  Component {
    id: gridComponent
    GridView {
      id: grid
      clip: true
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
        readonly property bool stringOnly: !!modelData.displayString
        width: grid.cellWidth
        height: grid.cellHeight

        Rectangle {
          id: tileBg
          anchors.fill: parent
          anchors.margins: Math.round(3 * root.s)
          radius: tile.selected ? Math.round(18 * root.s) : Math.min(width, height) / 2.6
          color: tile.selected ? root.primaryContainer : root.container
          clip: true
          Behavior on radius {
            NumberAnimation {
              duration: root.spring
              easing.type: Easing.OutBack
              easing.overshoot: root.overshoot
            }
          }
          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }
          StateLayer {
            radius: parent.radius
            hovered: tileArea.containsMouse && !tile.selected
            pressed: tileArea.pressed
          }

          LauncherEntryIcon {
            id: tileIcon
            readonly property real size: Math.round(Math.min(tileBg.width, tileBg.height) * (tile.modelData.hideLabel ? 0.62 : 0.5))
            width: size
            height: size
            anchors.horizontalCenter: parent.horizontalCenter
            y: tile.modelData.hideLabel ? (parent.height - height) / 2 : parent.height * 0.14
            entry: tile.modelData
            radius: Math.round(12 * root.s)
            glyphSize: Style.fontSizeXXL
            scale: tile.selected ? 1.12 : 1
            Behavior on scale {
              NumberAnimation {
                duration: root.spring
                easing.type: Easing.OutBack
                easing.overshoot: 2.2
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
            font.weight: tile.selected ? Style.fontWeightBold : Style.fontWeightMedium
            color: ShellColors.mOnSurface
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          // Item actions (pin) in the corner of the selected tile
          Row {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.marginXXS
            visible: tile.selected
            Repeater {
              model: tile.selected ? root.launcher.itemActions(tile.modelData) : []
              IconButton {
                required property var modelData
                icon: modelData.icon
                tooltip: modelData.tooltip || ""
                size: Math.round(26 * root.s)
                iconColor: ShellColors.mOnSurface
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
            color: ShellColors.mPrimary
          }
        }

        MouseArea {
          id: tileArea
          anchors.fill: parent
          z: -1
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          enabled: !Settings.data.appLauncher.ignoreMouseInput
          onEntered: if (!root.launcher.ignoreMouseHover)
                       root.launcher.selectIndex(tile.index)
          onClicked: root.launcher.activateIndex(tile.index)
        }
      }
    }
  }

  Component {
    id: singleComponent
    Rectangle {
      radius: Math.round(28 * root.s)
      color: root.container
      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginXL
        spacing: Style.marginM
        NText {
          Layout.fillWidth: true
          text: root.launcher.results.length > 0 ? root.launcher.results[0].name : ""
          pointSize: Style.fontSizeXXL
          font.weight: Style.fontWeightBold
          color: ShellColors.mPrimary
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
            color: ShellColors.mOnSurface
            wrapMode: Text.Wrap
            markdownTextEnabled: true
          }
        }
      }
    }
  }
}
