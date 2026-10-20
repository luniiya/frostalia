import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.Hardware
import qs.Services.Networking
import qs.Services.Power
import qs.Services.UI
import qs.Widgets

SmartPanel {
  id: root

  preferredWidth: Math.round(440 * Style.uiScaleRatio)
  preferredHeight: Math.round(460 * Style.uiScaleRatio)

  panelContent: Item {
    id: panelContent

    property real contentPreferredHeight: mainLayout.implicitHeight + Style.margin2L

    property var batteryWidgetInstance: BarService.lookupWidget("Battery", screen ? screen.name : null)
    readonly property var batteryWidgetSettings: batteryWidgetInstance ? batteryWidgetInstance.widgetSettings : null
    readonly property var batteryWidgetMetadata: BarWidgetRegistry.widgetMetadata["Battery"]
    readonly property bool powerProfileAvailable: PowerProfileService.available
    readonly property var powerProfiles: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
    readonly property bool profilesAvailable: PowerProfileService.available
    property int profileIndex: profileToIndex(PowerProfileService.profile)
    readonly property bool showPowerProfiles: panelID ? panelID.showPowerProfiles : resolveWidgetSetting("showPowerProfiles", false)
    readonly property bool showFrostaliaPerformance: panelID ? panelID.showFrostaliaPerformance : resolveWidgetSetting("showFrostaliaPerformance", false)
    readonly property bool isLowBattery: BatteryService.isLowBattery
    readonly property bool isCriticalBattery: BatteryService.isCriticalBattery
    readonly property var primaryDevice: BatteryService.primaryDevice

    function profileToIndex(p) {
      return powerProfiles.indexOf(p) ?? 1;
    }

    function indexToProfile(idx) {
      return powerProfiles[idx] ?? PowerProfile.Balanced;
    }

    function setProfileByIndex(idx) {
      var prof = indexToProfile(idx);
      profileIndex = idx;
      PowerProfileService.setProfile(prof);
    }

    function resolveWidgetSetting(key, defaultValue) {
      if (batteryWidgetSettings && batteryWidgetSettings[key] !== undefined)
        return batteryWidgetSettings[key];
      if (batteryWidgetMetadata && batteryWidgetMetadata[key] !== undefined)
        return batteryWidgetMetadata[key];
      return defaultValue;
    }

    Connections {
      target: PowerProfileService
      function onProfileChanged() {
        panelContent.profileIndex = panelContent.profileToIndex(PowerProfileService.profile);
      }
    }

    Connections {
      target: BarService
      function onActiveWidgetsChanged() {
        panelContent.batteryWidgetInstance = BarService.lookupWidget("Battery", screen ? screen.name : null);
      }
    }

    ColumnLayout {
      id: mainLayout
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // HEADER
      NBox {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Style.margin2M

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NIcon {
            pointSize: Style.fontSizeXXL
            color: (BatteryService.isCharging(primaryDevice) || BatteryService.isPluggedIn(primaryDevice)) ? ShellColors.mPrimary : (BatteryService.isCriticalBattery(primaryDevice) || BatteryService.isLowBattery(primaryDevice)) ? ShellColors.mError : ShellColors.mOnSurface
            icon: BatteryService.getIcon(BatteryService.getPercentage(primaryDevice), BatteryService.isCharging(primaryDevice), BatteryService.isPluggedIn(primaryDevice), BatteryService.isDeviceReady(primaryDevice))
          }

          ColumnLayout {
            spacing: Style.marginXXS
            Layout.fillWidth: true

            NText {
              text: I18n.tr("common.battery")
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: ShellColors.mOnSurface
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
          }

          NIconButton {
            icon: "close"
            tooltipText: I18n.tr("common.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: root.close()
          }
        }
      }

      // Charge level + health/time
      NBox {
        Layout.fillWidth: true
        implicitHeight: chargeLayout.implicitHeight + Style.margin2L
        visible: BatteryService.laptopBatteries.length > 0 || BatteryService.bluetoothBatteries.length > 0

        ColumnLayout {
          id: chargeLayout
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: Style.marginL

          // Laptop batteries section
          Repeater {
            model: BatteryService.laptopBatteries
            delegate: ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginS

                  RowLayout {
                    Item {
                      id: batteryInfoItem
                      implicitWidth: batteryInfoRow.implicitWidth
                      implicitHeight: batteryInfoRow.implicitHeight

                      RowLayout {
                        id: batteryInfoRow
                        anchors.fill: parent

                        NIcon {
                          icon: BatteryService.getIcon(BatteryService.getPercentage(modelData), BatteryService.isCharging(modelData), BatteryService.isPluggedIn(modelData), BatteryService.isDeviceReady(modelData))
                          color: (BatteryService.isCharging(modelData) || BatteryService.isPluggedIn(modelData)) ? ShellColors.mPrimary : (BatteryService.isCriticalBattery(modelData) || BatteryService.isLowBattery(modelData)) ? ShellColors.mError : ShellColors.mOnSurface
                        }

                        NText {
                          readonly property string dName: BatteryService.getDeviceName(modelData)
                          text: dName ? dName : I18n.tr("common.battery")
                          color: (BatteryService.isCharging(modelData) || BatteryService.isPluggedIn(modelData)) ? ShellColors.mPrimary : (BatteryService.isCriticalBattery(modelData) || BatteryService.isLowBattery(modelData)) ? ShellColors.mError : ShellColors.mOnSurface
                          pointSize: Style.fontSizeS
                        }
                      }

                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                          if (modelData.healthSupported) {
                            TooltipService.show(batteryInfoItem, `${I18n.tr("battery.battery-health")}: ${Math.round(modelData.healthPercentage)}%`);
                          }
                        }
                        onExited: TooltipService.hide(batteryInfoItem)
                      }
                    }

                    Item {
                      Layout.fillWidth: true
                    }

                    NText {
                      text: BatteryService.getTimeRemainingText(modelData)
                      pointSize: Style.fontSizeS
                      color: ShellColors.mOnSurfaceVariant
                    }
                  }

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS
                    Rectangle {
                      Layout.fillWidth: true
                      height: Math.round(8 * Style.uiScaleRatio)
                      radius: Math.min(Style.radiusL, height / 2)
                      color: ShellColors.mSurface

                      Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        radius: parent.radius
                        width: {
                          var p = BatteryService.getPercentage(modelData);
                          var ratio = Math.max(0, Math.min(1, p / 100));
                          return parent.width * ratio;
                        }
                        color: ShellColors.mPrimary
                      }
                    }

                    NText {
                      Layout.preferredWidth: 40 * Style.uiScaleRatio
                      horizontalAlignment: Text.AlignRight
                      text: `${BatteryService.getPercentage(modelData)}%`
                      color: (BatteryService.isCharging(modelData) || BatteryService.isPluggedIn(modelData)) ? ShellColors.mPrimary : (BatteryService.isCriticalBattery(modelData) || BatteryService.isLowBattery(modelData)) ? ShellColors.mError : ShellColors.mOnSurface
                      pointSize: Style.fontSizeS
                      font.weight: Style.fontWeightBold
                    }
                  }
                }
              }
            }
          }

          NDivider {
            Layout.fillWidth: true
            visible: BatteryService.laptopBatteries.length > 0 && BatteryService.bluetoothBatteries.length > 0
          }

          // Other devices (Bluetooth) section
          Repeater {
            model: BatteryService.bluetoothBatteries
            delegate: ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.marginS
              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NIcon {
                  icon: BluetoothService.getDeviceIcon(modelData)
                  color: (BatteryService.isCharging(modelData) || BatteryService.isPluggedIn(modelData)) ? ShellColors.mPrimary : (BatteryService.isCriticalBattery(modelData) || BatteryService.isLowBattery(modelData)) ? ShellColors.mError : ShellColors.mOnSurface
                }

                NText {
                  readonly property string dName: BatteryService.getDeviceName(modelData)
                  text: dName ? dName : I18n.tr("common.bluetooth")
                  color: (BatteryService.isCharging(modelData) || BatteryService.isPluggedIn(modelData)) ? ShellColors.mPrimary : (BatteryService.isCriticalBattery(modelData) || BatteryService.isLowBattery(modelData)) ? ShellColors.mError : ShellColors.mOnSurface
                  pointSize: Style.fontSizeS
                }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                Rectangle {
                  Layout.fillWidth: true
                  height: Math.round(8 * Style.uiScaleRatio)
                  radius: Math.min(Style.radiusL, height / 2)
                  color: ShellColors.mSurface

                  Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    radius: parent.radius
                    width: {
                      var p = BatteryService.getPercentage(modelData);
                      var ratio = Math.max(0, Math.min(1, p / 100));
                      return parent.width * ratio;
                    }
                    color: ShellColors.mPrimary
                  }
                }

                NText {
                  Layout.preferredWidth: 40 * Style.uiScaleRatio
                  horizontalAlignment: Text.AlignRight
                  text: `${BatteryService.getPercentage(modelData)}%`
                  color: (BatteryService.isCharging(modelData) || BatteryService.isPluggedIn(modelData)) ? ShellColors.mPrimary : (BatteryService.isCriticalBattery(modelData) || BatteryService.isLowBattery(modelData)) ? ShellColors.mError : ShellColors.mOnSurface
                  pointSize: Style.fontSizeS
                  font.weight: Style.fontWeightBold
                }
              }
            }
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        height: controlsLayout.implicitHeight + Style.margin2L
        visible: showPowerProfiles || showFrostaliaPerformance

        ColumnLayout {
          id: controlsLayout
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: Style.marginM

          ColumnLayout {
            visible: powerProfileAvailable && showPowerProfiles

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              NText {
                text: I18n.tr("battery.power-profile")
                font.weight: Style.fontWeightBold
                color: ShellColors.mOnSurface
                Layout.fillWidth: true
              }

              NText {
                text: PowerProfileService.getName(profileIndex)
                color: ShellColors.mOnSurfaceVariant
              }
            }

            NValueSlider {
              Layout.fillWidth: true
              from: 0
              to: 2
              stepSize: 1
              snapAlways: true
              heightRatio: 0.5
              value: profileIndex
              enabled: profilesAvailable
              onPressedChanged: (pressed, v) => {
                if (!pressed) {
                  setProfileByIndex(v);
                }
              }
              onMoved: v => {
                profileIndex = v;
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              NIcon {
                icon: "powersaver"
                pointSize: Style.fontSizeS
                color: PowerProfileService.getIcon() === "powersaver" ? ShellColors.mPrimary : ShellColors.mOnSurfaceVariant
              }

              NIcon {
                icon: "balanced"
                pointSize: Style.fontSizeS
                color: PowerProfileService.getIcon() === "balanced" ? ShellColors.mPrimary : ShellColors.mOnSurfaceVariant
                Layout.fillWidth: true
              }

              NIcon {
                icon: "performance"
                pointSize: Style.fontSizeS
                color: PowerProfileService.getIcon() === "performance" ? ShellColors.mPrimary : ShellColors.mOnSurfaceVariant
              }
            }
          }

          NDivider {
            Layout.fillWidth: true
            visible: showPowerProfiles && PowerProfileService.available && showFrostaliaPerformance
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: showFrostaliaPerformance

            NText {
              text: I18n.tr("toast.frostalia-performance.label")
              pointSize: Style.fontSizeM
              font.weight: Style.fontWeightBold
              color: ShellColors.mOnSurface
              Layout.fillWidth: true
            }

            NIcon {
              icon: PowerProfileService.frostaliaPerformanceMode ? "rocket" : "rocket-off"
              pointSize: Style.fontSizeL
              color: PowerProfileService.frostaliaPerformanceMode ? ShellColors.mPrimary : ShellColors.mOnSurfaceVariant
            }

            NToggle {
              checked: PowerProfileService.frostaliaPerformanceMode
              onToggled: checked => PowerProfileService.frostaliaPerformanceMode = checked
            }
          }
        }
      }
    }
  }
}
