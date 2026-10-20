import QtQuick
import "../../Helpers/WeatherScene.js" as WeatherScene

// Animated sky behind the current conditions: drifting clouds, rain with
// splashes, lightning, snow, stars, meteors and blown leaves.
// Adapted from Clavis Shell (GPL-3.0), a QML recreation of Steve Gardner's
// Animated Weather Cards (MIT, see licenses/AnimatedWeatherCards-MIT.txt).
Item {
  id: root

  property int weatherCode: 0
  property bool night: false
  property real windSpeedMs: 0
  property real windGustsMs: 0
  property bool animate: visible

  readonly property string weatherType: WeatherScene.type(weatherCode)
  readonly property bool windy: WeatherScene.windy(weatherType, windSpeedMs, windGustsMs)
  readonly property string visualType: WeatherScene.visualType(weatherType, windy)
  readonly property var colors: WeatherScene.palette(visualType, night)
  readonly property color textColor: WeatherScene.onSkyColor(colors)

  property bool componentReady: false
  property var cloudBands: []
  property var rainLayers: [[], [], []]
  property var splashes: []
  property var lightningStrikes: []
  property var meteors: []
  property real lightningCooldown: 0
  property var snowflakes: []
  property int nextLeafId: 0

  readonly property real cloudMaskOpacity: 0.18
  readonly property real frameBaseDt: 33 / 1000.0
  readonly property int windLeafTargetCount: 3
  readonly property int snowflakeTargetCount: 24
  readonly property bool isRainScene: weatherType === "rain" || weatherType === "storm"
  readonly property bool hasSnowScene: weatherType === "snow"
  readonly property bool hasMeteorScene: night && visualType === "clear"
  readonly property bool hasLeafScene: windy
  readonly property int cloudBandCount: WeatherScene.cloudBandCount(visualType)
  readonly property bool fastParticleScene: isRainScene || hasSnowScene || windy
  // Clear daytime is only the static gradient, so the canvas and timer stay off.
  readonly property bool hasCanvasScene: night || cloudBandCount > 0 || isRainScene || hasSnowScene

  function alphaColor(hex, alpha) {
    const value = String(hex).replace("#", "");
    const r = parseInt(value.slice(0, 2), 16);
    const g = parseInt(value.slice(2, 4), 16);
    const b = parseInt(value.slice(4, 6), 16);
    return "rgba(" + r + "," + g + "," + b + "," + alpha + ")";
  }

  function resetVisualScenes() {
    initCloudBands();
    resetRainScene();
    resetLightningScene();
    resetMeteorScene();
    resetSnowScene();
    resetLeafScene();
  }

  // Clouds -------------------------------------------------------------------

  function cloudProfile(index) {
    const wide = Math.max(width, 1);
    const heights = [0.255, 0.335, 0.405];
    const speeds = [1.0, 0.72, 0.48];
    const i = Math.max(0, Math.min(index, 2));
    const bandHeight = wide * heights[i];
    return {
      "height": bandHeight,
      "arch": bandHeight + wide * 0.124 + Math.random() * wide * 0.124,
      "speed": speeds[i]
    };
  }

  function initCloudBands() {
    const bands = [];
    for (let i = 0; i < cloudBandCount; ++i) {
      const profile = cloudProfile(i);
      bands.push({
                   "offset": Math.random() * Math.max(width, 1),
                   "height": profile.height,
                   "arch": profile.arch,
                   "speed": profile.speed,
                   "toneIndex": i
                 });
    }
    cloudBands = bands;
    canvas.requestPaint();
  }

  function drawCloudBandShape(ctx, offset, bandHeight, archHeight) {
    const w = Math.max(width, 1);
    const startX = -w + offset;
    ctx.beginPath();
    ctx.moveTo(startX, 0);
    ctx.lineTo(startX + w * 2.0, 0);
    ctx.quadraticCurveTo(startX + w * 3.0, bandHeight * 0.5, startX + w * 2.0, bandHeight);
    ctx.quadraticCurveTo(startX + w * 1.5, archHeight, startX + w, bandHeight);
    ctx.quadraticCurveTo(startX + w * 0.5, archHeight, startX, bandHeight);
    ctx.quadraticCurveTo(startX - w, bandHeight * 0.5, startX - w, 0);
    ctx.closePath();
  }

  function drawCloudBand(ctx, band) {
    ctx.fillStyle = [colors.cloud1, colors.cloud2, colors.cloud3][band.toneIndex];
    drawCloudBandShape(ctx, band.offset, band.height, band.arch);
    ctx.fill();
    ctx.fillStyle = alphaColor("#6a7078", cloudMaskOpacity);
    drawCloudBandShape(ctx, band.offset, band.height, band.arch);
    ctx.fill();
  }

  // Rain ---------------------------------------------------------------------

  function rainStrokeColor() {
    return weatherType === "storm" ? "#d7deec" : "#0000ff";
  }

  function resetRainScene() {
    rainLayers = [[], [], []];
    splashes = [];
    canvas.requestPaint();
  }

  function makeRainDrop() {
    const lineWidth = Math.random() * 3;
    const layerIndex = Math.max(0, Math.min(2, 2 - Math.floor(lineWidth)));
    rainLayers[layerIndex].push({
                                  "x": 20 + Math.random() * Math.max(1, width - 40),
                                  "width": lineWidth,
                                  "len": weatherType === "storm" ? 35 : 14,
                                  "age": 0,
                                  "delay": Math.random(),
                                  "duration": 1
                                });
  }

  function quadraticSamples(controlX, controlY, endX, endY) {
    const steps = 20;
    const points = [
      {
        "x": 0,
        "y": 0,
        "len": 0
      }
    ];
    let previous = {
      "x": 0,
      "y": 0
    };
    let total = 0;
    for (let i = 1; i <= steps; ++i) {
      const t = i / steps;
      const inverse = 1 - t;
      const point = {
        "x": 2 * inverse * t * controlX + t * t * endX,
        "y": 2 * inverse * t * controlY + t * t * endY
      };
      total += Math.sqrt(Math.pow(point.x - previous.x, 2) + Math.pow(point.y - previous.y, 2));
      points.push({
                    "x": point.x,
                    "y": point.y,
                    "len": total
                  });
      previous = point;
    }
    return {
      "points": points,
      "totalLength": total
    };
  }

  function makeSplash(x) {
    const storm = weatherType === "storm";
    const randomX = Math.random() * 80 - 40;
    const curve = quadraticSamples(randomX, -(Math.random() * (storm ? 120 : 100)), randomX * 2, 80);
    splashes.push({
                    "x": x,
                    "y": height,
                    "segmentLength": storm ? 30 : 20,
                    "duration": storm ? 0.7 : 0.5,
                    "age": 0,
                    "samples": curve.points,
                    "totalLength": curve.totalLength
                  });
  }

  function updateRain(dt) {
    let dropCount = 0;
    for (let layerIndex = 0; layerIndex < rainLayers.length; ++layerIndex) {
      const layer = rainLayers[layerIndex];
      for (let i = layer.length - 1; i >= 0; --i) {
        const drop = layer[i];
        drop.age += dt;
        if (drop.age >= drop.delay + drop.duration) {
          if (drop.width > 2)
            makeSplash(drop.x);
          layer.splice(i, 1);
        }
      }
      dropCount += layer.length;
    }
    const target = weatherType === "storm" ? 60 : 20;
    for (; dropCount < target; ++dropCount)
      makeRainDrop();

    for (let i = splashes.length - 1; i >= 0; --i) {
      splashes[i].age += dt;
      if (splashes[i].age >= splashes[i].duration)
        splashes.splice(i, 1);
    }
  }

  function sampleAtLength(samples, target) {
    if (target <= 0)
      return samples[0];
    for (let i = 1; i < samples.length; ++i) {
      const current = samples[i];
      if (target <= current.len) {
        const previous = samples[i - 1];
        const ratio = (target - previous.len) / Math.max(0.0001, current.len - previous.len);
        return {
          "x": previous.x + (current.x - previous.x) * ratio,
          "y": previous.y + (current.y - previous.y) * ratio
        };
      }
    }
    return samples[samples.length - 1];
  }

  function drawRainLayer(ctx, layerIndex) {
    ctx.lineCap = "butt";
    ctx.strokeStyle = rainStrokeColor();
    const layer = rainLayers[layerIndex];
    for (let i = 0; i < layer.length; ++i) {
      const drop = layer[i];
      if (drop.age < drop.delay)
        continue;
      const progress = Math.min(1, (drop.age - drop.delay) / drop.duration);
      const top = -drop.len + (height + drop.len) * progress * progress;
      ctx.lineWidth = drop.width;
      ctx.beginPath();
      ctx.moveTo(drop.x, top);
      ctx.lineTo(drop.x, top + drop.len);
      ctx.stroke();
    }
  }

  function drawSplashes(ctx) {
    ctx.lineCap = "butt";
    ctx.strokeStyle = rainStrokeColor();
    for (let i = 0; i < splashes.length; ++i) {
      const splash = splashes[i];
      const progress = splash.age / splash.duration;
      const startLength = progress * splash.totalLength;
      const endLength = Math.min(splash.totalLength, startLength + splash.segmentLength);
      const strokeWidth = 2 * (1 - progress);
      if (strokeWidth <= 0.02 || endLength <= startLength)
        continue;
      const start = sampleAtLength(splash.samples, startLength);
      const end = sampleAtLength(splash.samples, endLength);
      ctx.lineWidth = strokeWidth;
      ctx.beginPath();
      ctx.moveTo(splash.x + start.x, splash.y + start.y);
      for (let s = 1; s < splash.samples.length - 1; ++s) {
        const sample = splash.samples[s];
        if (sample.len > startLength && sample.len < endLength)
          ctx.lineTo(splash.x + sample.x, splash.y + sample.y);
      }
      ctx.lineTo(splash.x + end.x, splash.y + end.y);
      ctx.stroke();
    }
  }

  // Lightning ----------------------------------------------------------------

  function randomLightningDelay() {
    return Math.max(0.08, Math.random() * 6.0);
  }

  function resetLightningScene() {
    lightningStrikes = [];
    lightningCooldown = randomLightningDelay();
  }

  // A jagged polyline spanning the card that quickly fades out
  function makeLightningStrike() {
    if (width <= 0 || height <= 0)
      return;
    const steps = 20;
    const margin = Math.min(width * 0.25, Math.max(24, width * 0.10));
    const jitter = Math.max(20, width * 0.07);
    const pathX = margin + Math.random() * Math.max(1, width - margin * 2);
    const points = [
      {
        "x": pathX,
        "y": 0
      }
    ];
    for (let i = 0; i < steps; ++i)
      points.push({
                    "x": pathX + (Math.random() * jitter - jitter * 0.5),
                    "y": (height / steps) * (i + 1)
                  });
    lightningStrikes.push({
                            "points": points,
                            "age": 0,
                            "duration": 1.0,
                            "strokeWidth": 2.8 + Math.random() * 1.2
                          });
  }

  function updateLightning(dt) {
    if (weatherType !== "storm") {
      lightningStrikes = [];
      return;
    }
    for (let i = lightningStrikes.length - 1; i >= 0; --i) {
      lightningStrikes[i].age += dt;
      if (lightningStrikes[i].age >= lightningStrikes[i].duration)
        lightningStrikes.splice(i, 1);
    }
    lightningCooldown -= dt;
    while (lightningCooldown <= 0) {
      makeLightningStrike();
      lightningCooldown += randomLightningDelay();
    }
  }

  function drawLightning(ctx) {
    let flash = 0;
    for (let i = 0; i < lightningStrikes.length; ++i) {
      const progress = Math.min(1, lightningStrikes[i].age / lightningStrikes[i].duration);
      flash = Math.max(flash, Math.pow(1 - progress, 10) * 0.22);
    }
    if (flash > 0.01) {
      ctx.fillStyle = "rgba(255,255,255," + flash + ")";
      ctx.fillRect(0, 0, width, height);
    }
    ctx.lineJoin = "round";
    ctx.lineCap = "round";
    for (let i = 0; i < lightningStrikes.length; ++i) {
      const strike = lightningStrikes[i];
      const opacity = Math.pow(1 - Math.min(1, strike.age / strike.duration), 4);
      if (opacity <= 0.01)
        continue;
      ctx.strokeStyle = "rgba(255,255,255," + opacity + ")";
      ctx.lineWidth = strike.strokeWidth;
      ctx.beginPath();
      ctx.moveTo(strike.points[0].x, strike.points[0].y);
      for (let p = 1; p < strike.points.length; ++p)
        ctx.lineTo(strike.points[p].x, strike.points[p].y);
      ctx.stroke();
    }
  }

  // Night sky ----------------------------------------------------------------

  function drawStars(ctx) {
    for (let i = 0; i < 34; ++i) {
      const twinkle = 0.4 + 0.6 * (0.5 + 0.5 * Math.sin(canvas.phase * (0.5 + (i % 4) * 0.09) + i * 1.3));
      const x = (i * 43 + (i % 3) * 29) % Math.max(width, 1);
      const y = (i * 27 + (i % 6) * 15) % Math.max(80, height * 0.48);
      ctx.fillStyle = alphaColor(colors.particle, twinkle * 0.56);
      ctx.beginPath();
      ctx.arc(x, y, 0.9 + (i % 3) * 0.35, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  function makeMeteor(delaySeconds) {
    const palette = ["#d2f7ff", "#d0e9ff", "#afd0ec", "#a4c2dc", "#ecead5", "#f0dc97"];
    const scale = 0.45 + Math.random() * 0.55;
    const size = Math.max(1, Math.min(width, height));
    const angle = (108 + Math.random() * 18) * Math.PI / 180.0;
    return {
      "active": false,
      "delay": delaySeconds,
      "progress": 0,
      "startX": width * (0.22 + Math.random() * 0.96),
      "startY": height * (-0.30 + Math.random() * 0.42),
      "dx": Math.cos(angle),
      "dy": Math.sin(angle),
      "travel": size * (0.50 + Math.random() * 0.26),
      "len": size * (0.24 + Math.random() * 0.14) * scale,
      "strokeWidth": 1.5 + scale * 1.5,
      "color": palette[Math.floor(Math.random() * palette.length)]
    };
  }

  function meteorDelay(firstSpawn) {
    return (firstSpawn ? 1.0 : 5.0) + Math.random() * (firstSpawn ? 6.0 : 12.0);
  }

  function resetMeteorScene() {
    const next = [];
    if (hasMeteorScene) {
      for (let i = 0; i < 3; ++i)
        next.push(makeMeteor(meteorDelay(true)));
    }
    meteors = next;
  }

  function updateMeteors(dt) {
    for (let i = 0; i < meteors.length; ++i) {
      const meteor = meteors[i];
      if (!meteor.active) {
        meteor.delay -= dt;
        if (meteor.delay <= 0)
          meteor.active = true;
        continue;
      }
      meteor.progress += dt * meteor.travel * 1.85;
      if (meteor.progress >= meteor.travel)
        meteors[i] = makeMeteor(meteorDelay(false));
    }
  }

  function drawMeteors(ctx) {
    ctx.lineCap = "round";
    for (let i = 0; i < meteors.length; ++i) {
      const meteor = meteors[i];
      if (!meteor.active)
        continue;
      const opacity = Math.sin(Math.min(1, meteor.progress / meteor.travel) * Math.PI) * 0.92;
      if (opacity <= 0.02)
        continue;
      const headX = meteor.startX + meteor.dx * meteor.progress;
      const headY = meteor.startY + meteor.dy * meteor.progress;
      const tailX = headX - meteor.dx * meteor.len;
      const tailY = headY - meteor.dy * meteor.len;
      ctx.strokeStyle = alphaColor(meteor.color, opacity * 0.16);
      ctx.lineWidth = meteor.strokeWidth * 2.4;
      ctx.beginPath();
      ctx.moveTo(tailX, tailY);
      ctx.lineTo(headX, headY);
      ctx.stroke();
      // Brighter and wider towards the head
      const segments = 7;
      for (let s = 0; s < segments; ++s) {
        const from = s / segments;
        const to = (s + 1) / segments;
        ctx.strokeStyle = alphaColor(meteor.color, opacity * (0.10 + 0.90 * Math.pow(to, 1.7)));
        ctx.lineWidth = meteor.strokeWidth * (0.30 + 0.70 * to);
        ctx.beginPath();
        ctx.moveTo(tailX + (headX - tailX) * from, tailY + (headY - tailY) * from);
        ctx.lineTo(tailX + (headX - tailX) * to, tailY + (headY - tailY) * to);
        ctx.stroke();
      }
      ctx.fillStyle = alphaColor("#ffffff", Math.min(1, opacity * 0.95));
      ctx.beginPath();
      ctx.arc(headX, headY, meteor.strokeWidth * 0.45, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  // Snow ---------------------------------------------------------------------

  function configureSnowflake(flake) {
    const scale = 0.5 + Math.random() * 0.5;
    const fallDuration = 3.0 + Math.random() * 5.0;
    flake.age = 0;
    flake.x = 20 + Math.random() * Math.max(0, width - 40);
    flake.y = -10;
    flake.endY = height + 10 * scale;
    flake.swayTarget = Math.random() * 150 - 75;
    flake.fallDuration = fallDuration;
    flake.radiusBase = 5 * scale;
    flake.alphaBase = 0.34 + scale * 0.42;
    return flake;
  }

  function resetSnowScene() {
    const next = [];
    if (hasSnowScene && width > 40 && height > 0) {
      for (let i = 0; i < snowflakeTargetCount; ++i) {
        const flake = configureSnowflake({});
        flake.age = Math.random() * flake.fallDuration;
        next.push(flake);
      }
    }
    snowflakes = next;
  }

  function updateSnow(dt) {
    for (let i = 0; i < snowflakes.length; ++i) {
      snowflakes[i].age += dt;
      if (snowflakes[i].age >= snowflakes[i].fallDuration)
        configureSnowflake(snowflakes[i]);
    }
  }

  function drawSnow(ctx) {
    ctx.fillStyle = colors.particle;
    for (let i = 0; i < snowflakes.length; ++i) {
      const flake = snowflakes[i];
      const fall = Math.min(1, flake.age / flake.fallDuration);
      const grow = 0.5 - 0.5 * Math.cos(Math.min(1, flake.age) * Math.PI);
      const radius = flake.radiusBase * grow;
      if (radius <= 0.05)
        continue;
      const sway = flake.swayTarget * 0.5 * (1 - Math.cos(flake.age * Math.PI / 3));
      ctx.globalAlpha = flake.alphaBase;
      ctx.beginPath();
      ctx.arc(flake.x + sway, flake.y + (flake.endY - flake.y) * fall, radius, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }

  // Leaves -------------------------------------------------------------------

  function makeLeafState() {
    const palette = ["#76993E", "#4A5E23", "#6D632F"];
    const span = Math.max(48, leafLayer.height);
    const areaY = span / 2;
    const startY = areaY + Math.random() * areaY;
    const endY = startY - (Math.random() * span - areaY);
    return {
      "leafId": ++nextLeafId,
      "scale": 0.5 + Math.random() * 0.5,
      "color": palette[Math.floor(Math.random() * palette.length)],
      "startRotation": Math.random() * 180,
      "endRotation": Math.random() * 360,
      "x0": -100,
      "y0": startY,
      "x1": leafLayer.width / 2,
      "y1": Math.random() * endY + endY / 3,
      "x2": leafLayer.width + 50,
      "y2": endY
    };
  }

  function scheduleLeafSpawn(delayMs) {
    if (!hasLeafScene || !animate || leafModel.count >= windLeafTargetCount) {
      leafSpawnTimer.stop();
      return;
    }
    leafSpawnTimer.interval = delayMs === undefined ? 260 + Math.random() * 420 : delayMs;
    leafSpawnTimer.restart();
  }

  function spawnLeaf() {
    if (hasLeafScene && leafModel.count < windLeafTargetCount && leafLayer.width > 0)
      leafModel.append(makeLeafState());
    scheduleLeafSpawn();
  }

  function removeLeaf(leafId) {
    for (let i = 0; i < leafModel.count; ++i) {
      if (leafModel.get(i).leafId === leafId) {
        leafModel.remove(i);
        break;
      }
    }
    scheduleLeafSpawn();
  }

  function resetLeafScene() {
    leafSpawnTimer.stop();
    leafModel.clear();
    scheduleLeafSpawn(0);
  }

  // Scene --------------------------------------------------------------------

  Rectangle {
    anchors.fill: parent
    opacity: 0.96
    gradient: Gradient {
      GradientStop {
        position: 0.0
        color: root.colors.top
      }
      GradientStop {
        position: 0.54
        color: root.colors.mid
      }
      GradientStop {
        position: 1.0
        color: root.colors.bottom
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    opacity: 0.20
    gradient: Gradient {
      GradientStop {
        position: 0.0
        color: root.alphaColor(root.colors.glow, 0.18)
      }
      GradientStop {
        position: 0.44
        color: root.alphaColor(root.colors.glow, 0.04)
      }
      GradientStop {
        position: 1.0
        color: "transparent"
      }
    }
  }

  ListModel {
    id: leafModel
  }

  Timer {
    id: leafSpawnTimer
    repeat: false
    onTriggered: root.spawnLeaf()
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    visible: root.hasCanvasScene
    opacity: 0.92
    renderStrategy: Canvas.Threaded

    property real phase: 0

    onPaint: {
      const ctx = getContext("2d");
      ctx.clearRect(0, 0, width, height);
      if (root.night)
        root.drawStars(ctx);
      if (root.hasMeteorScene)
        root.drawMeteors(ctx);
      // Back to front: rain falls between the cloud layers
      for (let i = root.cloudBands.length - 1; i >= 0; --i) {
        if (root.isRainScene)
          root.drawRainLayer(ctx, i);
        if (root.weatherType === "storm" && i === 0)
          root.drawLightning(ctx);
        root.drawCloudBand(ctx, root.cloudBands[i]);
      }
      if (root.isRainScene)
        root.drawSplashes(ctx);
      if (root.hasSnowScene)
        root.drawSnow(ctx);
    }
  }

  Item {
    id: leafLayer
    anchors.fill: parent
    clip: true
    opacity: 0.9
    visible: root.hasLeafScene || leafModel.count > 0

    Repeater {
      model: leafModel

      delegate: WeatherLeaf {
        required property var model
        leafId: model.leafId
        leafColor: model.color
        leafScale: model.scale
        x0: model.x0
        y0: model.y0
        x1: model.x1
        y1: model.y1
        x2: model.x2
        y2: model.y2
        startRotation: model.startRotation
        endRotation: model.endRotation
        animationRunning: root.animate
        onFinished: leafId => root.removeLeaf(leafId)
      }
    }
  }

  // Slight darkening at the bottom keeps text on the card readable
  Rectangle {
    anchors.fill: parent
    opacity: 0.18
    gradient: Gradient {
      GradientStop {
        position: 0.62
        color: "transparent"
      }
      GradientStop {
        position: 1.0
        color: root.alphaColor("#0d1220", root.night ? 0.12 : 0.09)
      }
    }
  }

  Timer {
    id: sceneTimer

    property double lastTickMs: 0

    interval: root.fastParticleScene ? 33 : 66
    running: root.animate && root.hasCanvasScene
    repeat: true
    onRunningChanged: lastTickMs = 0
    onTriggered: {
      const now = Date.now();
      const dt = lastTickMs > 0 ? Math.min(0.05, (now - lastTickMs) / 1000.0) : interval / 1000.0;
      const stepScale = dt / root.frameBaseDt;
      lastTickMs = now;
      const drift = root.cloudBands.length > 0 ? (root.windy ? 3.05 : 1.05) : 0;
      for (let i = 0; i < root.cloudBands.length; ++i) {
        const band = root.cloudBands[i];
        band.offset += drift * band.speed * stepScale;
        if (band.offset > root.width)
          band.offset -= root.width;
      }
      if (root.isRainScene)
        root.updateRain(dt);
      if (root.hasSnowScene)
        root.updateSnow(dt);
      root.updateLightning(dt);
      if (root.hasMeteorScene)
        root.updateMeteors(dt);
      canvas.phase += 0.04 * stepScale;
      canvas.requestPaint();
    }
  }

  Component.onCompleted: {
    componentReady = true;
    resetVisualScenes();
  }
  onWidthChanged: if (componentReady)
                    resetVisualScenes()
  onHeightChanged: if (componentReady)
                     resetVisualScenes()
  onVisualTypeChanged: if (componentReady)
                         resetVisualScenes()
  onWeatherTypeChanged: if (componentReady)
                          resetVisualScenes()
  onNightChanged: {
    resetMeteorScene();
    canvas.requestPaint();
  }
  onAnimateChanged: {
    if (animate) {
      resetSnowScene();
      resetLeafScene();
    } else {
      leafSpawnTimer.stop();
    }
  }
}
