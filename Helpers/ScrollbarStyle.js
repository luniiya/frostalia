.pragma library

function opacity(hovered, pressed) {
  if (pressed)
    return 0.9;
  return hovered ? 0.7 : 0.45;
}
