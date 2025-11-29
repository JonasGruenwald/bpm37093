export function setTimeout(callback, delay) {
  return globalThis.setTimeout(callback, delay);
}

export function clearTimeout(id) {
  return globalThis.clearTimeout(id);
}