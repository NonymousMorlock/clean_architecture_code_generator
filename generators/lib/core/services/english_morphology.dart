/// A utility class for English verb morphology, specifically for converting
/// verbs into their Past Participle (State) forms.
sealed class EnglishMorphology {
  const EnglishMorphology();

  // A lookup for common irregular verbs used in tech/business logic.
  // We check this first to be fast and accurate.
  static final Map<String, String> _irregularVerbs = {
    'go': 'Gone',
    'do': 'Done',
    'run': 'Ran',
    'get': 'Got', // or 'Gotten', but 'Got' is often cleaner in UI states
    'set': 'Set',
    'put': 'Put',
    'read': 'Read',
    'write': 'Written',
    'send': 'Sent',
    'pay': 'Paid',
    'buy': 'Bought',
    'seek': 'Sought',
    'find': 'Found',
    'make': 'Made',
    'build': 'Built',
    'bind': 'Bound',
    'feed': 'Fed',
    'lead': 'Led',
    'meet': 'Met',
    'lose': 'Lost',
    'quit': 'Quit',
    'sell': 'Sold',
    'sit': 'Sat',
    'win': 'Won',
    'auth': 'Authenticated', // Tech specific shortcut
    'sync': 'Synced',
  };

  /// Conjugates a verb to its Past Participle (State) form.
  /// e.g., verify -> Verified, submit -> Submitted, create -> Created
  static String convertToPastParticiple(String verb) {
    final lowerVerb = verb.toLowerCase();

    // 1. Check Irregular Map
    if (_irregularVerbs.containsKey(lowerVerb)) {
      return _irregularVerbs[lowerVerb]!;
    }

    // 2. Handle "Silent E" (create -> created, save -> saved)
    if (lowerVerb.endsWith('e')) {
      return '${verb}d';
    }

    // 3. Handle "Y" endings
    if (lowerVerb.endsWith('y')) {
      // Vowel + Y -> Just add 'ed' (play -> played, destroy -> destroyed)
      if (_endsWithVowelY(lowerVerb)) {
        return '${verb}ed';
      }
      // Consonant + Y -> ied (verify -> verified, modify -> modified)
      return '${verb.substring(0, verb.length - 1)}ied';
    }

    // 4. Handle CVC (Consonant-Vowel-Consonant) doubling
    // e.g., ban -> banned, log -> logged, submit -> submitted
    if (_isCVC(lowerVerb)) {
      final lastChar = verb.substring(verb.length - 1);
      return '$verb$lastChar'
          'ed';
    }

    // 5. Default Rule
    return '${verb}ed';
  }

  /// Checks if word ends in Vowel + Y (e.g., play, destroy)
  static bool _endsWithVowelY(String word) {
    if (word.length < 2) return false;
    final secondLast = word[word.length - 2];
    return 'aeiou'.contains(secondLast);
  }

  /// Checks for Consonant-Vowel-Consonant pattern at the end of the word.
  /// This usually triggers a double consonant.
  static bool _isCVC(String word) {
    if (word.length < 3) return false;

    // Tech exceptions: 'listen', 'open' do not double, but 'submit' does.
    // For a generator, strict CVC on the last 3 chars is
    // usually 99% correct for action verbs.

    const vowels = 'aeiou';
    final len = word.length;
    final c1 = word[len - 3];
    final v = word[len - 2];
    final c2 = word[len - 1];

    final isC1 = !vowels.contains(c1);
    final isV = vowels.contains(v);
    // w and x never double (mixed, bowed)
    final isC2 = !vowels.contains(c2) && !'wx'.contains(c2);

    return isC1 && isV && isC2;
  }
}
