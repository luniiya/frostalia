import QtQuick
import "../../../../Helpers/KeycapStyle.js" as KeycapStyle

// Notification history: a round bell sticker. A new notification makes the
// bell wiggle and the count bubble bounce in; do-not-disturb dims it.
KeycapFace {
  id: face

  readonly property int count: Math.max(0, Math.floor(Number(faceData.count) || 0))
  readonly property bool showBadge: faceData.showBadge !== undefined ? !!faceData.showBadge : true
  readonly property bool dnd: !!faceData.dnd
  readonly property color badgeColor: faceData.badgeColor !== undefined && faceData.badgeColor.a > 0 ? faceData.badgeColor : kit.error
  readonly property string label: KeycapStyle.countLabel(count, 9)
  property int _lastCount: count

  ownsIcon: true
  sink: sticker.y + sticker.faceY

  onCountChanged: {
    if (count > _lastCount && kit.animated) {
      wiggle.restart();
      badgePop.restart();
    }
    _lastCount = count;
  }

  FaceSticker {
    id: sticker
    face: face
    radius: Math.min(width, height) / 2
    tilt: KeycapStyle.tilt("NotificationHistory", face.kit.tiltMax)
    bodyColor: face.dnd ? face.kit.mix(face.kit.fill, face.kit.ink, 0.3) : face.kit.fill

    FaceGlyph {
      id: bell
      kit: face.kit
      anchors.centerIn: parent
      icon: face.host ? face.host.icon : "bell"
      size: face.host && face.host.buttonSize ? face.host.buttonSize * 0.42 : 9
      color: face.host && face.host.colorFg !== undefined ? face.host.colorFg : face.kit.fillText
      transformOrigin: Item.Top
    }
  }

  // Count bubble, top right, outside the sticker's tilt
  Rectangle {
    id: badge
    readonly property bool shown: face.showBadge && face.count > 0
    z: 2
    height: Math.max(8, Math.round(face.height * 0.42))
    width: Math.max(height, badgeText.implicitWidth + 4)
    radius: height / 2
    x: face.width - width * 0.75
    y: face.centerShift + sticker.faceY - height * 0.2
    color: face.badgeColor
    border.color: face.kit.ink
    border.width: Math.max(1, face.kit.outline - 0.5)
    scale: shown ? 1 : 0
    visible: scale > 0

    Behavior on scale {
      NumberAnimation {
        duration: face.kit.normal
        easing.type: Easing.OutBack
        easing.overshoot: face.kit.popOvershoot
      }
    }

    Text {
      id: badgeText
      anchors.centerIn: parent
      text: face.label
      font.family: face.kit.fontFamily
      font.weight: face.kit.fontWeightBold
      font.pixelSize: Math.max(6, Math.round(badge.height * 0.72))
      color: face.kit.readableOn(badge.color)
    }
  }

  SequentialAnimation {
    id: wiggle
    loops: 2
    NumberAnimation {
      target: bell
      property: "rotation"
      to: 18
      duration: Math.round(face.kit.fast / 2)
    }
    NumberAnimation {
      target: bell
      property: "rotation"
      to: -18
      duration: face.kit.fast
    }
    NumberAnimation {
      target: bell
      property: "rotation"
      to: 0
      duration: Math.round(face.kit.fast / 2)
    }
  }

  SequentialAnimation {
    id: badgePop
    NumberAnimation {
      target: badge
      property: "y"
      to: badge.y - 3
      duration: Math.round(face.kit.fast / 2)
    }
    NumberAnimation {
      target: badge
      property: "y"
      to: face.centerShift + sticker.faceY - badge.height * 0.2
      duration: face.kit.normal
      easing.type: Easing.OutBounce
    }
    ScriptAction {
      script: badge.y = Qt.binding(() => face.centerShift + sticker.faceY - badge.height * 0.2)
    }
  }
}
