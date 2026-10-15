.pragma library

function minutes(value, fallback) {
  const number = Number(value);
  return isFinite(number) && number >= 1 ? Math.min(180, Math.floor(number)) : fallback;
}

function duration(phase, workMinutes, breakMinutes) {
  return minutes(phase === "work" ? workMinutes : breakMinutes, phase === "work" ? 50 : 10) * 60000;
}

function create(workMinutes) {
  return { phase: "work", running: false, remainingMs: duration("work", workMinutes, 10), deadline: 0 };
}

function advance(state, now, workMinutes, breakMinutes) {
  if (!state.running)
    return state;
  let phase = state.phase;
  let deadline = state.deadline;
  if (now >= deadline) {
    // Skip complete cycles after a long delay (for example, system suspend).
    const cycle = duration("work", workMinutes, breakMinutes) + duration("break", workMinutes, breakMinutes);
    deadline += Math.floor((now - deadline) / cycle) * cycle;
    while (now >= deadline) {
      phase = phase === "work" ? "break" : "work";
      deadline += duration(phase, workMinutes, breakMinutes);
    }
  }
  return { phase: phase, running: true, remainingMs: Math.max(0, deadline - now), deadline: deadline };
}

function start(state, now) {
  return { phase: state.phase, running: true, remainingMs: state.remainingMs, deadline: now + state.remainingMs };
}

function pause(state, now, workMinutes, breakMinutes) {
  const current = advance(state, now, workMinutes, breakMinutes);
  return { phase: current.phase, running: false, remainingMs: current.remainingMs, deadline: 0 };
}

function formatRemaining(milliseconds) {
  const seconds = Math.max(0, Math.ceil(milliseconds / 1000));
  return String(Math.floor(seconds / 60)).padStart(2, "0") + ":" + String(seconds % 60).padStart(2, "0");
}

function dayKey(timestamp) {
  const date = new Date(timestamp);
  return date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, "0") + "-" + String(date.getDate()).padStart(2, "0");
}

// Integral of repeating work intervals, anchored to the current phase deadline.
function workMilliseconds(state, from, to, workMinutes, breakMinutes) {
  if (!state || !state.running || to <= from)
    return 0;
  const work = duration("work", workMinutes, breakMinutes);
  const rest = duration("break", workMinutes, breakMinutes);
  const cycle = work + rest;
  const anchor = state.phase === "work" ? state.deadline - work : state.deadline - rest - work;
  function integral(timestamp) {
    const offset = timestamp - anchor;
    const cycles = Math.floor(offset / cycle);
    return cycles * work + Math.min(offset - cycles * cycle, work);
  }
  return Math.max(0, integral(to) - integral(from));
}

function addStudyTime(totals, state, from, to, workMinutes, breakMinutes) {
  const result = Object.assign({}, totals);
  if (!state || !state.running || to <= from)
    return result;
  let cursor = from;
  while (cursor < to) {
    const date = new Date(cursor);
    const nextDay = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1).getTime();
    const end = Math.min(to, nextDay);
    const seconds = workMilliseconds(state, cursor, end, workMinutes, breakMinutes) / 1000;
    if (seconds > 0) {
      const key = dayKey(cursor);
      result[key] = (Number(result[key]) || 0) + seconds;
    }
    cursor = end;
  }
  return result;
}

function stats(totals, now) {
  const today = dayKey(now);
  let total = 0;
  let best = 0;
  let days = 0;
  Object.keys(totals).forEach(function(key) {
    const seconds = Math.max(0, Number(totals[key]) || 0);
    total += seconds;
    best = Math.max(best, seconds);
    if (seconds >= 60)
      days++;
  });
  let streak = 0;
  const cursor = new Date(now);
  // Keep yesterday's streak until today has had a chance to begin.
  if (!(totals[today] >= 60))
    cursor.setDate(cursor.getDate() - 1);
  while (totals[dayKey(cursor.getTime())] >= 60) {
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }
  return { todaySeconds: Math.max(0, Number(totals[today]) || 0), totalSeconds: total, bestSeconds: best, days: days, streak: streak, xp: Math.floor(total / 60) * 10 };
}

function formatStudyTime(seconds) {
  const minutes = Math.floor(Math.max(0, seconds) / 60);
  return Math.floor(minutes / 60) + "h " + String(minutes % 60).padStart(2, "0") + "m";
}

function formatStudyCompact(seconds) {
  const minutes = Math.floor(Math.max(0, seconds) / 60);
  if (minutes < 60)
    return minutes + "m";
  return Math.floor(minutes / 60) + "h" + String(minutes % 60).padStart(2, "0");
}
