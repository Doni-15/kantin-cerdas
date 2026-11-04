import 'package:characters/characters.dart';

/// Batas bersama untuk entity, controller, dan input UI pelanggan.
abstract final class CustomerInputLimits {
  static const maxQuantity = 99;
  static const maxNoteLength = 300;
  static const maxSearchLength = 120;
  static bool validQuantity(int value) => value >= 1 && value <= maxQuantity;
  static bool validPrice(int value) => value >= 1 && value <= 10000000;
  static bool validNote(String value) =>
      value.characters.length <= maxNoteLength;
}
