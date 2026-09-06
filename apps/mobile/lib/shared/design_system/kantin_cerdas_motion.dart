import 'package:flutter/material.dart';

abstract final class KantinCerdasMotion {
  static Duration durationOf(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
  }

  static AnimationStyle styleOf(BuildContext context) {
    final duration = durationOf(context);
    return AnimationStyle(duration: duration, reverseDuration: duration);
  }
}
