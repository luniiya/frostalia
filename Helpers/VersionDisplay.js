.pragma library

function installedVersion(currentVersion, commitHash) {
  return commitHash || currentVersion;
}
