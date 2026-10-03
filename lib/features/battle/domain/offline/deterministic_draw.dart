import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Port of the server's `DeterministicDraw` (PHP), used to replay offline bot
/// matches server-side.
///
/// ## Why this file is this paranoid
///
/// Offline play means the phone simulates bot opponents with no connection.
/// The server verifies those matches afterwards by replaying *its own* copy of
/// this algorithm. If the Dart and PHP copies disagree by a single draw, every
/// honest offline user gets quarantined as a fraudster — silently, and hardest
/// on the people least able to report it. Parity is the feature.
///
/// ## The algorithm
///
/// ```text
/// drawSeed := seed + "|" + botKey + "|" + questionIndex + "|" + questionId
///
/// draw(drawSeed, label, min, max):
///     bytes = SHA-256( utf8(drawSeed) ++ utf8(0x00) ++ utf8(label) )   // raw
///     value = big-ENDIAN unsigned int32 from bytes[0..3]              // 0..2^32-1
///     span  = max - min + 1
///     return min + (value * span) ~/ 2^32                             // floored
/// ```
///
/// Note there is no `answer` in the `drawSeed` and no time component, so the
/// function is a pure hash: identical inputs always yield identical output on
/// every platform. Do **not** introduce a global PRNG here — seeding
/// `Random()` or `dart:math` would reintroduce exactly the platform
/// dependence the hash exists to eliminate.
abstract final class DeterministicDraw {
  /// The NUL byte that separates the seed from the label in the digest input.
  ///
  /// It is part of the wire contract with PHP. Dropping it (or substituting a
  /// space or `|`) yields a completely different, still plausible-looking
  /// stream of numbers, so it is written out by name rather than inlined.
  static const int labelSeparator = 0x00;

  /// `2^32`, the divisor of the scaling step. Exactly representable as a
  /// double, which matters because this also runs on web (see [_maxSafeSpan]).
  static const int modulus = 0x100000000;

  /// Largest span whose *worst-case* product still fits a web double exactly.
  ///
  /// What has to stay exact is not the span but the product `value * span`, so
  /// the bound is taken against the largest `value` the digest can produce:
  ///
  /// ```text
  /// floor(2^53 / (2^32 - 1)) == 2097152 == 2^21
  /// ```
  ///
  /// Bounding the span against `2^53` instead would be wrong by a factor of
  /// ~4.3e9 and would wave through ranges where a web build loses the product's
  /// low bits and returns a plausible wrong answer. The widest realistic window
  /// here is about 11k, so this leaves roughly 180x headroom while still being
  /// the mathematically correct cut-off.
  static const int _maxSafeSpan = 0x200000;

  /// Raw 32-byte SHA-256 digest of `utf8(drawSeed) ++ 0x00 ++ utf8(label)`.
  ///
  /// Both operands are encoded as UTF-8. Using `utf16`/`latin1` here changes
  /// every byte for non-ASCII seeds, and the committed golden vectors include a
  /// deliberately accented seed to catch that.
  static List<int> digest(String drawSeed, String label) {
    final input = <int>[
      ...utf8.encode(drawSeed),
      labelSeparator,
      ...utf8.encode(label),
    ];
    return sha256.convert(input).bytes;
  }

  /// The first four digest bytes read as an **unsigned big-endian** 32-bit int,
  /// in the range `0 .. 4294967295`.
  ///
  /// The decode is written out by hand rather than delegated to
  /// `ByteData.getUint32` without an explicit endianness argument: that defaults
  /// to `Endian.host` and would silently read little-endian on every mainstream
  /// target. The result would still be a plausible-looking number in range, so
  /// the bug would not announce itself; it would just desynchronise Dart from
  /// PHP and quarantine honest players.
  ///
  /// The top byte is *multiplied* into place rather than shifted, and that is
  /// deliberate for web. The Dart web-numbers contract specifies `<<` as a
  /// signed 32-bit operation, under which `0x80 << 24` is negative and every
  /// such draw would land below its minimum — plausible-looking, web-only.
  /// Today's dart2js happens to paper over that by emitting an unsigned
  /// conversion (`... >>> 0`) after the shift chain, so a plain shift chain
  /// *currently* produces correct values; building the correctness of every
  /// draw on that compiler courtesy is exactly the fragile-silent-divergence
  /// class this file exists to avoid. A multiplication is exact under the
  /// documented contract, under dart2js, under DDC, and on the VM: the sum
  /// peaks at `4294967295`, inside the `2^53` a web double holds exactly and
  /// far inside 64 bits. The lower shifts are safe under both readings
  /// because `0xFF << 16` and `0xFF << 8` stay below `2^31`.
  ///
  /// No masking is needed: crypto digest bytes are already `0..255`, every
  /// operand is non-negative, and the sum cannot exceed `2^32 - 1`.
  static int value(String drawSeed, String label) {
    final bytes = digest(drawSeed, label);
    return (bytes[0] * 0x1000000) +
        (bytes[1] << 16) +
        (bytes[2] << 8) +
        bytes[3];
  }

  /// `min + floor(value * span / 2^32)`, with `span = max - min + 1`.
  ///
  /// The multiplication is exact: the widest case in practice is
  /// `4294967295 * 11251 ≈ 4.8e13`, comfortably inside both a 64-bit Dart int
  /// and the `2^53` a web build can hold. [_maxSafeSpan] guards the range
  /// instead of trusting that, because on web an overflowing product would
  /// return a plausible wrong answer rather than an error.
  static int draw(
    String drawSeed,
    String label, {
    required int min,
    required int max,
  }) {
    if (max < min) {
      throw ArgumentError.value(max, 'max', 'must not be below min ($min)');
    }
    final raw = value(drawSeed, label);
    final span = max - min + 1;
    if (span > _maxSafeSpan) {
      throw RangeError.value(
        span,
        'span',
        'exceeds $_maxSafeSpan; value * span would exceed 2^53 and lose '
            'precision on web',
      );
    }
    // `~/` is integer division truncating toward zero. Every operand here is
    // non-negative, so truncation equals floor — the PHP `intdiv` the server
    // uses. Plain `/` would be float division and drift by up to 1ms.
    return min + (raw * span ~/ modulus);
  }

  /// Builds `seed|botKey|questionIndex|questionId`.
  ///
  /// All four parts are interpolated verbatim with no normalisation: the server
  /// does the same, and "helpfully" trimming or lower-casing here would change
  /// the digest input and desynchronise the two implementations.
  static String seedFor({
    required String seed,
    required String botKey,
    required int questionIndex,
    required int questionId,
  }) {
    return '$seed|$botKey|$questionIndex|$questionId';
  }

  /// Roster sampling label, e.g. `shuffle:5`.
  static String shuffleLabel(int index) => 'shuffle:$index';
}
