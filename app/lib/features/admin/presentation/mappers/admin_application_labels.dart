import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';

String adminApplicationLabel(CanteenApplicationStatus? status) =>
    switch (status) {
      null => 'Semua',
      CanteenApplicationStatus.submitted => 'Diajukan',
      CanteenApplicationStatus.reviewing => 'Sedang ditinjau',
      CanteenApplicationStatus.approved => 'Disetujui',
      CanteenApplicationStatus.rejected => 'Ditolak',
    };
