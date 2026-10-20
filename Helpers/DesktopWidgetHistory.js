.pragma library

var limit = 60;

function snapshot(layout) {
  return JSON.parse(JSON.stringify(layout));
}

function create(layout) {
  return { past: [], current: snapshot(layout), future: [] };
}

function record(history, layout) {
  if (JSON.stringify(history.current) === JSON.stringify(layout))
    return history;
  return {
    past: history.past.concat([snapshot(history.current)]).slice(-limit),
    current: snapshot(layout),
    future: []
  };
}

function undo(history) {
  if (history.past.length === 0)
    return history;
  return {
    past: history.past.slice(0, -1),
    current: snapshot(history.past[history.past.length - 1]),
    future: [snapshot(history.current)].concat(history.future)
  };
}

function redo(history) {
  if (history.future.length === 0)
    return history;
  return {
    past: history.past.concat([snapshot(history.current)]).slice(-limit),
    current: snapshot(history.future[0]),
    future: history.future.slice(1)
  };
}
