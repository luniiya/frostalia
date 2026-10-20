.pragma library

function gigabytes(value) {
  const amount = parseFloat(value);
  if (!isFinite(amount) || amount < 0)
    return "0";
  return amount < 10 ? amount.toFixed(1) : String(Math.round(amount));
}

// "7.8/16G"; only the used amount while the total is unknown.
function label(usedGb, totalGb) {
  const total = parseFloat(totalGb);
  if (!isFinite(total) || total <= 0)
    return gigabytes(usedGb) + "G";
  return gigabytes(usedGb) + "/" + gigabytes(total) + "G";
}
