import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/session/user_role.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/profile_identity_header.dart';

import '../../../../support/simulation/simulation.dart';
import '../../../../support/simulation/simulation_overrides.dart';

void main() {
  group('ProfileIdentityHeader', () {
    testWidgets(
      'ProfileIdentityHeader merender nama dan username reaktif dari authStateProvider meskipun prop user awal belum diperbarui',
      (tester) async {
        final store = SimulationStore.memory();
        await store.signIn('customer-1');
        const stalePropUser = User(
          id: 'customer-1',
          username: 'username_lama',
          email: 'lama@kampus.ac.id',
          name: 'Nama Lama Prop',
          role: UserRole.customer,
          isActive: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: simulationOverrides(store),
            child: const MaterialApp(
              home: Scaffold(body: ProfileIdentityHeader(user: stalePropUser)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final activeSessionUser = store.sessionUser!;
        expect(find.text(activeSessionUser.name), findsOneWidget);
        expect(find.text('@${activeSessionUser.username}'), findsOneWidget);
        expect(find.text('Nama Lama Prop'), findsNothing);
      },
    );
  });
}
