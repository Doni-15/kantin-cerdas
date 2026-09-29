import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/canteen_application_repository.dart';
import 'package:kantin_cerdas/features/customer/domain/validators/canteen_application_validator.dart';

class SubmitCanteenApplicationUseCase {
  const SubmitCanteenApplicationUseCase(this.repository);

  final CanteenApplicationRepository repository;

  Future<CanteenApplication> execute({
    required String name,
    required String description,
    required String address,
  }) async {
    final normalizedName = name.trim();
    final normalizedDescription = description.trim();
    final normalizedAddress = address.trim();

    final errors = <String, String>{};

    final nameError = CanteenApplicationValidator.name(normalizedName);
    if (nameError != null) errors['name'] = nameError;

    final descriptionError =
        CanteenApplicationValidator.description(normalizedDescription);
    if (descriptionError != null) errors['description'] = descriptionError;

    final addressError =
        CanteenApplicationValidator.address(normalizedAddress);
    if (addressError != null) errors['address'] = addressError;

    if (errors.isNotEmpty) {
      throw CanteenApplicationValidationFailure(errors);
    }

    return repository.submit(
      name: normalizedName,
      description: normalizedDescription,
      address: normalizedAddress,
    );
  }
}
