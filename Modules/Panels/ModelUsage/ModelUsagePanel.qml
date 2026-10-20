import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Helpers/ModelUsageLogic.js" as ModelUsageLogic
import qs.Commons
import qs.Modules.MainScreen
import qs.Services.System
import qs.Widgets

// Details of the enabled AI usage providers, opened from the ModelUsage bar widget
SmartPanel {
  id: root

  preferredWidth: Math.round(420 * Style.uiScaleRatio)
  preferredHeight: Math.round(580 * Style.uiScaleRatio)

  panelContent: Item {
    id: panelContent

    readonly property var providers: ModelUsageService.enabledProviders
    readonly property var provider: providers.length > 0 ? providers[ModelUsageLogic.clampIndex(tabBar.currentIndex, providers.length)] : null

    function usageColor(percent) {
      const level = ModelUsageLogic.usageLevel(percent);
      if (level === "critical")
        return ShellColors.mError;
      if (level === "warning")
        return Qt.alpha(ShellColors.mError, 0.72);
      return ShellColors.mPrimary;
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Header
      NBox {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Style.margin2M

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NIcon {
            icon: "ai"
            pointSize: Style.fontSizeXXL
            color: ShellColors.mPrimary
          }

          NText {
            text: I18n.tr("model-usage.title")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: ShellColors.mOnSurface
            Layout.fillWidth: true
          }

          NIconButton {
            icon: "refresh"
            tooltipText: I18n.tr("common.refresh")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: ModelUsageService.refresh()
          }

          NIconButton {
            icon: "close"
            tooltipText: I18n.tr("common.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: root.close()
          }
        }
      }

      NTabBar {
        id: tabBar
        Layout.fillWidth: true
        visible: panelContent.providers.length > 1
        distributeEvenly: true

        Repeater {
          model: panelContent.providers

          NTabButton {
            required property var modelData
            required property int index
            text: modelData.providerName
            tabIndex: index
            checked: tabBar.currentIndex === index
          }
        }
      }

      NText {
        visible: !panelContent.provider
        text: I18n.tr("model-usage.no-providers")
        pointSize: Style.fontSizeM
        color: ShellColors.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        Layout.topMargin: Style.marginXL
      }

      Flickable {
        visible: !!panelContent.provider
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: details.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: details
          width: parent.width
          spacing: Style.marginM

          readonly property var p: panelContent.provider

          // Provider name and plan
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NText {
              text: details.p ? details.p.providerName : ""
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: ShellColors.mOnSurface
              Layout.fillWidth: true
            }

            Rectangle {
              visible: details.p && details.p.tierLabel !== ""
              color: Qt.alpha(ShellColors.mPrimary, 0.15)
              radius: Style.radiusXS
              implicitWidth: tierText.implicitWidth + Style.marginL
              implicitHeight: tierText.implicitHeight + Style.marginS

              NText {
                id: tierText
                anchors.centerIn: parent
                text: details.p ? details.p.tierLabel : ""
                pointSize: Style.fontSizeS
                font.weight: Style.fontWeightSemiBold
                color: ShellColors.mPrimary
              }
            }
          }

          NText {
            visible: details.p && !details.p.ready && details.p.statusText === ""
            text: I18n.tr("model-usage.waiting")
            pointSize: Style.fontSizeS
            color: ShellColors.mOnSurfaceVariant
          }

          // Problem with auth or the API
          NBox {
            visible: details.p && details.p.statusText !== ""
            Layout.fillWidth: true
            color: Qt.alpha(ShellColors.mError, 0.12)
            implicitHeight: statusColumn.implicitHeight + Style.margin2L

            ColumnLayout {
              id: statusColumn
              anchors.fill: parent
              anchors.margins: Style.marginL
              spacing: Style.marginXS

              NText {
                text: details.p ? details.p.statusText : ""
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightSemiBold
                color: ShellColors.mError
              }

              NText {
                text: details.p ? details.p.helpText : ""
                pointSize: Style.fontSizeXS
                color: ShellColors.mOnSurfaceVariant
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }
          }

          // Rate limits
          NBox {
            visible: details.p && details.p.primary.percent >= 0
            Layout.fillWidth: true
            implicitHeight: limitsColumn.implicitHeight + Style.margin2L

            ColumnLayout {
              id: limitsColumn
              anchors.fill: parent
              anchors.margins: Style.marginL
              spacing: Style.marginM

              NText {
                text: I18n.tr("model-usage.rate-limits")
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightSemiBold
                color: ShellColors.mPrimary
              }

              Repeater {
                model: details.p ? [details.p.primary, details.p.secondary].filter(l => l.percent >= 0) : []

                ColumnLayout {
                  required property var modelData
                  Layout.fillWidth: true
                  spacing: Style.marginXS

                  RowLayout {
                    Layout.fillWidth: true

                    NText {
                      text: ModelUsageService.limitLabel(modelData)
                      pointSize: Style.fontSizeS
                      color: ShellColors.mOnSurfaceVariant
                      Layout.fillWidth: true
                    }

                    NText {
                      text: Math.round(modelData.percent * 100) + "%"
                      pointSize: Style.fontSizeS
                      font.weight: Style.fontWeightBold
                      color: ModelUsageLogic.usageLevel(modelData.percent) === "normal" ? ShellColors.mOnSurface : panelContent.usageColor(modelData.percent)
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    color: Qt.alpha(ShellColors.mOutline, 0.2)
                    radius: Style.radiusXXS

                    Rectangle {
                      anchors.left: parent.left
                      anchors.top: parent.top
                      anchors.bottom: parent.bottom
                      radius: Style.radiusXXS
                      color: panelContent.usageColor(modelData.percent)
                      width: parent.width * Math.min(1, Math.max(0, modelData.percent))

                      Behavior on width {
                        NumberAnimation {
                          duration: Style.animationNormal
                          easing.type: Easing.OutCubic
                        }
                      }
                    }
                  }

                  NText {
                    readonly property string resetIn: ModelUsageLogic.formatResetTime(modelData.resetAt, Time.now.getTime())
                    visible: resetIn !== ""
                    text: resetIn === "now" ? I18n.tr("model-usage.resets-now") : I18n.tr("model-usage.resets-in", {
                                                                                            "time": resetIn
                                                                                          })
                    pointSize: Style.fontSizeXS
                    color: ShellColors.mOnSurfaceVariant
                  }
                }
              }
            }
          }

          // Today
          NBox {
            visible: details.p && details.p.ready && details.p.hasLocalStats
            Layout.fillWidth: true
            implicitHeight: todayColumn.implicitHeight + Style.margin2L

            ColumnLayout {
              id: todayColumn
              anchors.fill: parent
              anchors.margins: Style.marginL
              spacing: Style.marginM

              NText {
                text: I18n.tr("model-usage.today")
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightSemiBold
                color: ShellColors.mPrimary
              }

              RowLayout {
                spacing: Style.marginXL

                Repeater {
                  model: details.p ? [
                                       {
                                         "value": String(details.p.todayPrompts),
                                         "label": I18n.tr("model-usage.prompts")
                                       },
                                       {
                                         "value": String(details.p.todaySessions),
                                         "label": I18n.tr("model-usage.sessions")
                                       },
                                       {
                                         "value": ModelUsageLogic.formatTokenCount(details.p.todayTotalTokens),
                                         "label": I18n.tr("model-usage.tokens")
                                       }
                                     ] : []

                  ColumnLayout {
                    required property var modelData
                    spacing: Style.marginXXS

                    NText {
                      text: modelData.value
                      pointSize: Style.fontSizeXXL
                      font.weight: Style.fontWeightBold
                      color: ShellColors.mOnSurface
                    }
                    NText {
                      text: modelData.label
                      pointSize: Style.fontSizeXS
                      color: ShellColors.mOnSurfaceVariant
                    }
                  }
                }
              }

              Repeater {
                model: details.p ? ModelUsageLogic.entries(details.p.todayTokensByModel) : []

                RowLayout {
                  required property var modelData
                  Layout.fillWidth: true

                  NText {
                    text: ModelUsageLogic.friendlyModelName(modelData.key)
                    pointSize: Style.fontSizeS
                    color: ShellColors.mOnSurfaceVariant
                    Layout.fillWidth: true
                  }
                  NText {
                    text: I18n.tr("model-usage.token-count", {
                                    "count": ModelUsageLogic.formatTokenCount(modelData.value)
                                  })
                    pointSize: Style.fontSizeS
                    font.weight: Style.fontWeightSemiBold
                    color: ShellColors.mOnSurface
                  }
                }
              }
            }
          }

          // Last 7 days
          NBox {
            id: weekBox
            visible: details.p && details.p.recentDays.length > 0
            Layout.fillWidth: true
            implicitHeight: weekColumn.implicitHeight + Style.margin2L

            readonly property real maxCount: {
              let max = 1;
              for (const d of (details.p ? details.p.recentDays : []))
                max = Math.max(max, d.messageCount || 0);
              return max;
            }

            ColumnLayout {
              id: weekColumn
              anchors.fill: parent
              anchors.margins: Style.marginL
              spacing: Style.marginS

              NText {
                text: I18n.tr("model-usage.last-7-days")
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightSemiBold
                color: ShellColors.mPrimary
              }

              Repeater {
                model: details.p ? details.p.recentDays : []

                RowLayout {
                  id: dayRow
                  required property var modelData
                  Layout.fillWidth: true
                  spacing: Style.marginS

                  NText {
                    text: modelData.date ? I18n.locale.toString(new Date(modelData.date + "T00:00:00"), "ddd dd/MM") : ""
                    pointSize: Style.fontSizeXS
                    color: ShellColors.mOnSurfaceVariant
                    Layout.preferredWidth: Math.round(64 * Style.uiScaleRatio)
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 12
                    color: Qt.alpha(ShellColors.mOutline, 0.2)
                    radius: Style.radiusXXS

                    Rectangle {
                      anchors.left: parent.left
                      anchors.top: parent.top
                      anchors.bottom: parent.bottom
                      radius: Style.radiusXXS
                      color: ShellColors.mPrimary
                      width: parent.width * ((dayRow.modelData.messageCount || 0) / weekBox.maxCount)
                    }
                  }

                  NText {
                    text: ModelUsageLogic.formatTokenCount(modelData.messageCount || 0)
                    pointSize: Style.fontSizeXS
                    font.weight: Style.fontWeightSemiBold
                    color: ShellColors.mOnSurface
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: Math.round(36 * Style.uiScaleRatio)
                  }
                }
              }
            }
          }

          // All time, per model
          NBox {
            visible: details.p && Object.keys(details.p.modelUsage).length > 0
            Layout.fillWidth: true
            implicitHeight: allTimeColumn.implicitHeight + Style.margin2L

            ColumnLayout {
              id: allTimeColumn
              anchors.fill: parent
              anchors.margins: Style.marginL
              spacing: Style.marginM

              NText {
                text: I18n.tr("model-usage.all-time")
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightSemiBold
                color: ShellColors.mPrimary
              }

              RowLayout {
                visible: details.p && details.p.totalPrompts > 0
                spacing: Style.marginXL

                Repeater {
                  model: details.p ? [
                                       {
                                         "value": ModelUsageLogic.formatTokenCount(details.p.totalPrompts),
                                         "label": I18n.tr("model-usage.messages")
                                       },
                                       {
                                         "value": String(details.p.totalSessions),
                                         "label": I18n.tr("model-usage.sessions")
                                       }
                                     ] : []

                  ColumnLayout {
                    required property var modelData
                    spacing: Style.marginXXS

                    NText {
                      text: modelData.value
                      pointSize: Style.fontSizeXL
                      font.weight: Style.fontWeightBold
                      color: ShellColors.mOnSurface
                    }
                    NText {
                      text: modelData.label
                      pointSize: Style.fontSizeXS
                      color: ShellColors.mOnSurfaceVariant
                    }
                  }
                }
              }

              Repeater {
                model: details.p ? ModelUsageLogic.entries(details.p.modelUsage) : []

                ColumnLayout {
                  required property var modelData
                  Layout.fillWidth: true
                  spacing: Style.marginXS

                  NText {
                    text: ModelUsageLogic.friendlyModelName(modelData.key)
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightSemiBold
                    color: ShellColors.mOnSurface
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.marginM
                    spacing: Style.marginXXS

                    Repeater {
                      model: [
                        {
                          "label": I18n.tr("model-usage.input"),
                          "value": modelData.value.inputTokens
                        },
                        {
                          "label": I18n.tr("model-usage.output"),
                          "value": modelData.value.outputTokens
                        },
                        {
                          "label": I18n.tr("model-usage.cache-read"),
                          "value": modelData.value.cacheReadInputTokens
                        },
                        {
                          "label": I18n.tr("model-usage.cache-write"),
                          "value": modelData.value.cacheCreationInputTokens
                        }
                      ]

                      delegate: RowLayout {
                        required property var modelData
                        spacing: Style.marginL

                        NText {
                          text: modelData.label
                          pointSize: Style.fontSizeXS
                          color: ShellColors.mOnSurfaceVariant
                          Layout.preferredWidth: Math.round(80 * Style.uiScaleRatio)
                        }
                        NText {
                          text: ModelUsageLogic.formatTokenCount(modelData.value || 0)
                          pointSize: Style.fontSizeXS
                          font.weight: Style.fontWeightSemiBold
                          color: ShellColors.mOnSurface
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
