.pragma library

// Scheme folders whose names differ from the name shown and saved in settings.
var displayNames = {
  "Tokyo-Night": "Tokyo Night",
  "Rosepine": "Rose Pine"
};

var defaultScheme = "Eldritch";

function displayName(folderName) {
  return displayNames[folderName] || folderName;
}

function folderName(name) {
  for (const folder in displayNames) {
    if (displayNames[folder] === name)
      return folder;
  }
  return name;
}

// Scheme names saved before the original theme was renamed back to Noctalia.
function migratedName(name) {
  return name === "Frostalia (default)" || name === "Frostalia (legacy)" ? "Noctalia" : name;
}
