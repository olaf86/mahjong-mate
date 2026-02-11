const String shareDomain = 'mahjong-mate-app.web.app';

String normalizeShareCode(String raw) {
  final trimmed = raw.trim().toUpperCase();
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.startsWith('MJM-')) {
    return trimmed;
  }
  return 'MJM-$trimmed';
}

String shareUrlFor(String shareCode) {
  final normalized = normalizeShareCode(shareCode);
  return 'https://$shareDomain/r/$normalized';
}
