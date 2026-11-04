import 'dart:math';

/// Menghasilkan ID mutasi/submisi heksadesimal kriptografis yang aman
/// untuk mencegah benturan `Idempotency-Key` lintas perangkat dan sesi.
String generateSecureMutationId({int byteLength = 24}) {
  if (byteLength < 16) {
    throw ArgumentError.value(
      byteLength,
      'byteLength',
      'Panjang byte minimal 16 untuk menjamin keunikan ID mutasi.',
    );
  }
  final random = Random.secure();
  return List.generate(
    byteLength,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
