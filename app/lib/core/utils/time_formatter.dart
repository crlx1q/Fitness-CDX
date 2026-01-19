String formatMinutes(int minutes) {
  if (minutes <= 0) return '0м';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours > 0 && mins > 0) {
    return '${hours}ч ${mins}м';
  }
  if (hours > 0) {
    return '${hours}ч';
  }
  return '${minutes}м';
}
