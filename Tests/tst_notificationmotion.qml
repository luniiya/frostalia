import QtQuick
import QtTest
import "../Helpers/NotificationMotion.js" as Motion

TestCase {
  name: "NotificationMotion"

  function test_inputRegionFollowsBothAxesImmediately() {
    const origin = Motion.inputOrigin(0, 0, 836, 592, 198, 198, 1, -120, 90);
    compare(origin.x, 78);
    compare(origin.y, 288);
    const scaled = Motion.inputOrigin(20, 30, 836, 592, 198, 198, 0.8, -120, 90);
    fuzzyCompare(scaled.x, 142, 0.001);
    fuzzyCompare(scaled.y, 337.6, 0.001);
  }

  function test_springRespectsDisplayEdge() {
    var state = {
      position: -120,
      velocity: 1000
    };
    for (var frame = 0; frame < 180; frame++) {
      state = Motion.springStep(state.position, state.velocity, 16, 160, false, {
                                  negative: 160,
                                  positive: 6
                                });
      verify(state.position >= -160);
      verify(state.position <= 6);
    }
    verify(state.settled);
  }

  function test_timeoutStaysPausedDuringDrag() {
    verify(Motion.shouldResumeTimeout(false, false));
    verify(!Motion.shouldResumeTimeout(true, false));
    verify(!Motion.shouldResumeTimeout(false, true));
    verify(!Motion.shouldResumeTimeout(true, true));
  }

  function test_dragIsBoundedAndSymmetric() {
    compare(Motion.dragOffset(0, 40), 0);
    for (const distance of [1, 18, 120, 10000]) {
      verify(Motion.dragOffset(distance, 40) > 0);
      verify(Motion.dragOffset(distance, 40) < 40);
      compare(Motion.dragOffset(-distance, 40), -Motion.dragOffset(distance, 40));
    }
    compare(Motion.dragOffset(100, 0), 0);
  }

  function test_flick_data() {
    return [
          {
            tag: "short fast horizontal",
            x: 25,
            y: 0,
            vx: 1000,
            vy: 0,
            dismiss: true
          },
          {
            tag: "short fast vertical",
            x: 0,
            y: -25,
            vx: 0,
            vy: -1000,
            dismiss: true
          },
          {
            tag: "slow drag rebounds",
            x: 60,
            y: 20,
            vx: 100,
            vy: 100,
            dismiss: false
          },
          {
            tag: "reversed throw rebounds",
            x: 30,
            y: 0,
            vx: -1500,
            vy: 0,
            dismiss: false
          },
          {
            tag: "tiny jitter never dismisses",
            x: 5,
            y: 5,
            vx: 2000,
            vy: 2000,
            dismiss: false
          },
          {
            tag: "distance horizontal",
            x: -140,
            y: 0,
            vx: 0,
            vy: 0,
            dismiss: true
          },
          {
            tag: "distance vertical",
            x: 0,
            y: 120,
            vx: 0,
            vy: 0,
            dismiss: true
          }
        ];
  }

  function test_flick(data) {
    compare(Motion.shouldDismiss(data.x, data.y, data.vx, data.vy, 440, 180), data.dismiss);
  }

  function test_velocityRejectsStaleSamples() {
    compare(Motion.sampleVelocity(1000, 20, 0), 0);
    compare(Motion.sampleVelocity(1000, 20, 200), 0);
    verify(Motion.sampleVelocity(0, 20, 16) > 800);
    verify(Motion.sampleVelocity(0, 10000, 1) <= 2400);
  }

  function test_springConvergesWithOvershoot() {
    var state = {
      position: 35,
      velocity: 180
    };
    var crossedOrigin = false;
    for (var frame = 0; frame < 180; frame++) {
      state = Motion.springStep(state.position, state.velocity, frame % 5 === 0 ? 64 : 16, 40, false);
      verify(Math.abs(state.position) <= 40);
      verify(isFinite(state.velocity));
      if (state.position < 0)
        crossedOrigin = true;
    }
    verify(crossedOrigin);
    verify(state.settled);
    compare(state.position, 0);
    compare(state.velocity, 0);
  }

  function test_reducedMotionStopsImmediately() {
    const state = Motion.springStep(30, 400, 16, 40, true);
    compare(state.position, 0);
    compare(state.velocity, 0);
    verify(state.settled);
  }
}
