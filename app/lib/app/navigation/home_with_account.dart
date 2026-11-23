import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/account_view.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';

class HomeWithAccount extends ConsumerStatefulWidget {
  const HomeWithAccount({
    super.key,
    required this.account,
    required this.builder,
  });
  final AuthAccount account;
  final Widget Function(VoidCallback onAccount) builder;

  @override
  ConsumerState<HomeWithAccount> createState() => _HomeWithAccountState();
}

class _HomeWithAccountState extends ConsumerState<HomeWithAccount> {
  var _accountOpen = false;

  @override
  Widget build(BuildContext context) {
    void closeAccount() => setState(() => _accountOpen = false);
    final isOwner = widget.account.role == AuthRole.owner;

    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: _accountOpen,
          child: TickerMode(
            enabled: !_accountOpen,
            child: widget.builder(() => setState(() => _accountOpen = true)),
          ),
        ),

        if (_accountOpen)
          PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) closeAccount();
            },

            child: AuthAccountScreen(
              account: widget.account,
              onBack: closeAccount,
              onOpenOwnerArea: isOwner
                  ? () {
                      closeAccount();
                      ref
                          .read(
                            ownerCustomerViewProvider(
                              widget.account.id,
                            ).notifier,
                          )
                          .switchToOwner();
                    }
                  : null,
            ),
          ),
      ],
    );
  }
}
