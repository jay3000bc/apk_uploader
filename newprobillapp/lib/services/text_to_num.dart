

int text2num(String s) {
  var small = {
    'zero': 0,
    'one': 1,
    'ek': 1,
    'won': 1,
    'on': 1,
    'en': 1,
    'two': 2,
    'to': 2,
    'do': 2,
    'too': 2,
    'three': 3,
    'tree': 3,
    'tre': 3,
    'tray': 3,
    'trae': 3,
    'four': 4,
    'for': 4,
    'fore': 4,
    'fire': 4,
    'five': 5,
    'hive': 5,
    'six': 6,
    'sex': 6,
    'seks': 6,
    'seven': 7,
    'eight': 8,
    'ate': 8,
    'nine': 9,
    'line': 9,
    'nein': 9,
    'neon': 9,
    'ten': 10,
    'tin': 10,
    'eleven': 11,
    'elleve': 11,
    'eleve': 11,
    'twelve': 12,
    'tolv': 12,
    'toll': 12,
    'tall': 12,
    'doll': 12,
    'thirteen': 13,
    'tretten': 13,
    'fourteen': 14,
    'forteen': 14,
    'foreteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'sexteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'lineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90
  };

  var large = {
    'thousand': 1000,
  };
  var a = s.toLowerCase().split(RegExp(r'[\s-]+'));
  var n = 0;
  var g = 0;
  var lastSmall = 0; // To track the last small number found
  for (var w in a) {
    var x = small[w];
    if (x != null) {
      g += x;
      lastSmall = x;
    } else if (int.tryParse(w) != null) {
      if (g != 0) {
        n += g;
        g = 0;
      }
      n += int.tryParse(w)!;
      lastSmall = int.tryParse(w)!;
    } else if (w == 'hundred') {
      g *= 100;
    } else if (large.containsKey(w)) {
      n += g * large[w]!;
      g = 0;
    } else {}
  }
  // Check if there's any remaining small number to add
  if (g != 0) {
    n += g;
  }

  return n;
}

