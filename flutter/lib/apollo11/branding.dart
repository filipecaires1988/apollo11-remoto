const String apollo11DisplayName = 'Apollo11 Remoto';

final _displayTokens = RegExp(
  r'''(?:[a-z][a-z0-9+.-]*://|www\.)[^\s<>"']+|"(?:[a-z]:[\\/]|/)[^"\r\n]*"|'(?:[a-z]:[\\/]|/)[^'\r\n]*'|(\bRustDesk\b)''',
  caseSensitive: false,
);
final _pathPrefix = RegExp(r'[A-Za-z0-9_./\\@:-]');
final _pathSuffix = RegExp(r'^(?:[/\\]|\.[A-Za-z0-9_])');

String apollo11DisplayText(String text) {
  return text.replaceAllMapped(_displayTokens, (match) {
    // Keep actual URLs, file names and paths usable when shown in instructions.
    if (match.group(1) == null ||
        (match.start > 0 && _pathPrefix.hasMatch(text[match.start - 1])) ||
        _pathSuffix.hasMatch(text.substring(match.end))) {
      return match[0]!;
    }
    return apollo11DisplayName;
  });
}
