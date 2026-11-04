import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sinyal revisi lintas peran agar mutasi pada stan/menu/pesanan dapat
/// menyegarkan pembacaan katalog/pesanan tanpa impor lintas fitur langsung.
class SharedDataRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}

final sharedDataRevisionProvider =
    NotifierProvider<SharedDataRevisionNotifier, int>(
      SharedDataRevisionNotifier.new,
    );
