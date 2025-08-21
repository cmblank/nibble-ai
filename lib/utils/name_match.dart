import 'dart:math';

String canonicalizeName(String raw) {
  var s = raw.toLowerCase();
  s = s.replaceAll(RegExp(r"[\p{P}\p{S}]", unicode: true), ' ');
  final stop = <String>{
    'of', 'the', 'a', 'an', 'extra', 'virgin', 'fresh', 'large', 'small',
    'organic', 'and', 'or'
  };
  final tokens = s
      .split(RegExp(r"\s+"))
      .where((t) => t.isNotEmpty && !stop.contains(t))
      .map(_singularize)
      .toList();
  return tokens.join(' ').trim();
}

bool isFuzzyPantryMatch(String candidate, Set<String> pantryNames) {
  if (candidate.isEmpty || pantryNames.isEmpty) return false;
  final target = canonicalizeName(candidate);
  final canonPantry = pantryNames.map(canonicalizeName).toSet();
  if (canonPantry.contains(target)) return true;
  // Try head noun containment and edit distance threshold
  for (final p in canonPantry) {
    if (p.isEmpty) continue;
    if (target.contains(p) || p.contains(target)) return true;
    final dist = _levenshtein(target, p);
    if (dist <= 1 && (min(target.length, p.length) >= 5)) return true;
    // Token Jaccard similarity
    final a = target.split(' ').toSet();
    final b = p.split(' ').toSet();
    final inter = a.intersection(b).length;
    final union = a.union(b).length;
    if (union > 0 && inter / union >= 0.6) return true;
  }
  return false;
}

String _singularize(String t) {
  if (t.endsWith('ies') && t.length > 3) return '${t.substring(0, t.length - 3)}y';
  if (t.endsWith('es') && t.length > 2) return t.substring(0, t.length - 2);
  if (t.endsWith('s') && t.length > 1) return t.substring(0, t.length - 1);
  return t;
}

int _levenshtein(String a, String b) {
  final m = a.length, n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;
  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      dp[i][j] = min(
        dp[i - 1][j] + 1,
        min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost),
      );
    }
  }
  return dp[m][n];
}
