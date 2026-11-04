import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_recovery_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_page_body.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_stall_section.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/settings/owner_stall_form.dart';

class OwnerStallSettingsPage extends StatefulWidget {
  const OwnerStallSettingsPage({super.key});
  @override
  State<OwnerStallSettingsPage> createState() => _OwnerStallSettingsPageState();
}

class _OwnerStallSettingsPageState extends State<OwnerStallSettingsPage> {
  final _editor = GlobalKey<OwnerStallFormState>();

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.ownerCanteen);
    }
  }

  void _requestClose() {
    final editor = _editor.currentState;
    if (editor == null) {
      _leave();
    } else {
      editor.requestClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan stan'),
        leading: BackButton(onPressed: _requestClose),
      ),
      body: OwnerPageBody(
        title: 'Informasi stan',
        description: 'Atur identitas, waktu persiapan, dan status buka stan.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OwnerRecoveryBanner(),
            OwnerStallSection(
              builder: (stall) =>
                  OwnerStallForm(key: _editor, stall: stall, onClose: _leave),
            ),
          ],
        ),
      ),
    );
  }
}
