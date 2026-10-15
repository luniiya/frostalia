.pragma library

function resolve(configuredCommand, actionCommand) {
  const override = String(actionCommand || "").trim();
  return override || String(configuredCommand || "").trim();
}
