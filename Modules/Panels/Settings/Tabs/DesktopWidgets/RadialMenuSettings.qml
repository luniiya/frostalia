import QtQuick
import QtQuick.Layouts
import "../../../../../Helpers/RadialMenu.js" as RadialLogic
import qs.Commons
import qs.Services.UI
import qs.Widgets

// Settings for the desktop radial menu: on/off and the item tree editor. Tree edits go
// through Helpers/RadialMenu.js (addItem, updateItem, ...) and save the whole tree.
ColumnLayout {
  id: root

  spacing: Style.marginL

  readonly property var rows: RadialLogic.flatten(Settings.data.radialMenu.items)
  readonly property var actionModel: RadialLogic.actionIds().map(id => ({
    "key": id,
    "name": I18n.tr(RadialLogic.actions[id].labelKey)
  }))

  function save(tree) {
    Settings.data.radialMenu.items = tree;
  }

  function blankItem(action) {
    const item = {
      "action": action,
      "label": "",
      "labelKey": "",
      "icon": "",
      "arg": ""
    };
    if (action === "folder")
      item.children = [];
    return item;
  }

  function argPlaceholder(action) {
    if (action === "app")
      return I18n.tr("radial-menu.settings.app-placeholder");
    if (action === "wallpaper")
      return I18n.tr("radial-menu.settings.wallpaper-placeholder");
    if (action === "uiStyle")
      return I18n.tr("radial-menu.settings.ui-style-placeholder");
    return I18n.tr("radial-menu.settings.command-placeholder");
  }

  NDivider {
    Layout.fillWidth: true
  }

  NHeader {
    label: I18n.tr("radial-menu.settings.title")
    description: I18n.tr("radial-menu.settings.description")
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("radial-menu.settings.enabled-label")
    description: I18n.tr("radial-menu.settings.enabled-description")
    checked: Settings.data.radialMenu.enabled
    defaultValue: Settings.getDefaultValue("radialMenu.enabled")
    onToggled: checked => Settings.data.radialMenu.enabled = checked
  }

  NLabel {
    enabled: Settings.data.radialMenu.enabled
    label: I18n.tr("radial-menu.settings.items-label")
    description: I18n.tr("radial-menu.settings.items-description")
  }

  ColumnLayout {
    Layout.fillWidth: true
    enabled: Settings.data.radialMenu.enabled
    spacing: Style.marginS

    Repeater {
      model: root.rows

      delegate: RowLayout {
        id: row
        required property var modelData
        readonly property var item: modelData.item
        readonly property string argKind: RadialLogic.actions[item.action].arg

        Layout.fillWidth: true
        Layout.leftMargin: modelData.depth * Style.marginXL
        spacing: Style.marginS

        function update(changes) {
          root.save(RadialLogic.updateItem(Settings.data.radialMenu.items, row.modelData.path, row.modelData.index, changes));
        }

        NIconButton {
          icon: RadialLogic.iconFor(row.item)
          tooltipText: I18n.tr("radial-menu.settings.icon-tooltip")
          onClicked: {
            iconPicker.target = row;
            iconPicker.initialIcon = row.item.icon;
            iconPicker.open();
          }
          onRightClicked: row.update({
                                       "icon": ""
                                     })
        }

        NComboBox {
          Layout.preferredWidth: Math.round(170 * Style.uiScaleRatio)
          minimumWidth: Math.round(170 * Style.uiScaleRatio)
          model: root.actionModel
          currentKey: row.item.action
          onSelected: key => row.update({
                                          "action": key
                                        })
        }

        NTextInput {
          Layout.fillWidth: true
          text: row.item.label
          placeholderText: RadialMenuService.labelFor(Object.assign({}, row.item, {
                                                                      "label": ""
                                                                    }))
          onEditingFinished: {
            if (text !== row.item.label)
              row.update({
                           "label": text
                         });
          }
        }

        NTextInput {
          Layout.fillWidth: true
          visible: row.argKind !== ""
          text: row.item.arg
          placeholderText: root.argPlaceholder(row.item.action)
          onEditingFinished: {
            if (text !== row.item.arg)
              row.update({
                           "arg": text
                         });
          }
        }

        NIconButton {
          visible: row.item.action === "folder"
          icon: "plus"
          tooltipText: I18n.tr("radial-menu.settings.add-to-folder")
          onClicked: root.save(RadialLogic.addItem(Settings.data.radialMenu.items, row.modelData.path.concat([row.modelData.index]), root.blankItem("app")))
        }

        NIconButton {
          icon: "chevron-up"
          enabled: row.modelData.index > 0
          tooltipText: I18n.tr("radial-menu.settings.move-up")
          onClicked: root.save(RadialLogic.moveItem(Settings.data.radialMenu.items, row.modelData.path, row.modelData.index, -1))
        }

        NIconButton {
          icon: "chevron-down"
          enabled: row.modelData.index < row.modelData.count - 1
          tooltipText: I18n.tr("radial-menu.settings.move-down")
          onClicked: root.save(RadialLogic.moveItem(Settings.data.radialMenu.items, row.modelData.path, row.modelData.index, 1))
        }

        NIconButton {
          icon: "trash"
          tooltipText: I18n.tr("radial-menu.settings.remove")
          onClicked: root.save(RadialLogic.removeItem(Settings.data.radialMenu.items, row.modelData.path, row.modelData.index))
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NButton {
        text: I18n.tr("radial-menu.settings.add-item")
        icon: "plus"
        enabled: root.rows.filter(r => r.depth === 0).length < RadialLogic.maxItemsPerRing
        onClicked: root.save(RadialLogic.addItem(Settings.data.radialMenu.items, [], root.blankItem("command")))
      }

      NButton {
        text: I18n.tr("radial-menu.settings.reset")
        icon: "restore"
        outlined: true
        onClicked: root.save(RadialLogic.normalizeItems(Settings.getDefaultValue("radialMenu.items")))
      }
    }
  }

  NIconPicker {
    id: iconPicker
    property var target: null
    onIconSelected: iconName => {
      if (target)
        target.update({
                        "icon": iconName
                      });
    }
  }
}
