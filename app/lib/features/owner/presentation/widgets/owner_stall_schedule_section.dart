import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerStallScheduleSection extends StatelessWidget {
  const OwnerStallScheduleSection({
    super.key,
    required this.schedules,
    required this.busy,
    required this.onToggleOpenDay,
    required this.onPickTime,
    required this.onSaveSchedule,
  });

  final List<OwnerScheduleDay> schedules;
  final bool busy;
  final void Function(int index, bool isOpenDay) onToggleOpenDay;
  final void Function(int index, {required bool isStart}) onPickTime;
  final VoidCallback onSaveSchedule;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Jam Operasional (Informatif)'),
        subtitle: const Text(
          'Hanya informasi jadwal; tidak mengubah status Buka/Tutup otomatis.',
        ),
        children: [
          for (var i = 0; i < schedules.length; i++) ...[
            const Divider(height: 1),
            ListTile(
              title: Text(schedules[i].dayLabel),
              subtitle: Text(
                schedules[i].isOpenDay
                    ? '${schedules[i].openTime ?? '08:00'} – ${schedules[i].closeTime ?? '17:00'}'
                    : 'Libur / Tutup',
              ),
              trailing: Switch(
                value: schedules[i].isOpenDay,
                onChanged: busy ? null : (val) => onToggleOpenDay(i, val),
              ),
            ),
            if (schedules[i].isOpenDay)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KcSpacing.md,
                  0,
                  KcSpacing.md,
                  KcSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => onPickTime(i, isStart: true),
                        child: Text(
                          'Buka: ${schedules[i].openTime ?? '08:00'}',
                        ),
                      ),
                    ),
                    const SizedBox(width: KcSpacing.xs),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => onPickTime(i, isStart: false),
                        child: Text(
                          'Tutup: ${schedules[i].closeTime ?? '17:00'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.all(KcSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: busy ? null : onSaveSchedule,
                child: const Text('Simpan Jam Operasional'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
