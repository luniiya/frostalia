.pragma library

function normalizeVersion(version) {
  if (!version)
    return "";
  return version.startsWith("v") ? version.substring(1) : version;
}

function parseVersionParts(version) {
  const clean = normalizeVersion(version);
  if (!clean)
    return [];
  return clean.split(/[^0-9]+/).filter(part => part.length > 0).map(part => parseInt(part));
}

function compareVersions(a, b) {
  if (a === b)
    return 0;
  const partsA = parseVersionParts(a);
  const partsB = parseVersionParts(b);
  const length = Math.max(partsA.length, partsB.length);
  for (var i = 0; i < length; i++) {
    const valA = partsA[i] || 0;
    const valB = partsB[i] || 0;
    if (valA > valB)
      return 1;
    if (valA < valB)
      return -1;
  }
  return 0;
}

