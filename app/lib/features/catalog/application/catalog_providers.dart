import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/catalog/data/catalog_repository.dart'
    show CatalogRepository;
import 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(authRepositoryProvider)),
);

final firstStallPageProvider = FutureProvider.autoDispose
    .family<CatalogPage, String>((ref, accountId) {
      final session = ref.read(authControllerProvider).asData?.value;
      if (session == null || session.account.id != accountId) {
        throw const AuthException(
          'INVALID_SESSION',
          'Sesi berakhir. Silakan masuk kembali.',
        );
      }
      return ref
          .watch(catalogRepositoryProvider)
          .list(session, CatalogKind.stalls);
    }, retry: (_, _) => null);
