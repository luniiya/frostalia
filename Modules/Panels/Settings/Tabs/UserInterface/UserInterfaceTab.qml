import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  NComboBox {
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginL
    label: I18n.tr("panels.user-interface.ui-style-label")
    description: I18n.tr("panels.user-interface.ui-style-description")
    model: Style.uiStyleChoices.map(style => ({
      "key": style.key,
      "name": I18n.tr(style.labelKey)
    }))
    currentKey: Style.uiStyleId
    defaultValue: Settings.getDefaultValue("ui.style")
    onSelected: key => Settings.data.ui.style = key
  }

  NTabBar {
    id: subTabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: I18n.tr("common.appearance")
      tabIndex: 0
      checked: subTabBar.currentIndex === 0
    }
    NTabButton {
      text: I18n.tr("common.panels")
      tabIndex: 1
      checked: subTabBar.currentIndex === 1
    }
    NTabButton {
      text: I18n.tr("common.screen-corners")
      tabIndex: 2
      checked: subTabBar.currentIndex === 2
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.marginL
  }

  NTabView {
    id: tabView
    currentIndex: subTabBar.currentIndex

    AppearanceSubTab {}
    PanelsSubTab {}
    ScreenCornersSubTab {}
  }
}
