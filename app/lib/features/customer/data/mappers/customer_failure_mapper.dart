import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_cancellation_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';

CustomerFeatureFailure mapCustomerReadApiException(
  ApiException error, {
  bool mapBadRequestToRejected = false,
}) {
  final statusCode = error.statusCode;
  if (error.type == ApiExceptionType.timeout ||
      error.type == ApiExceptionType.connection ||
      (error.type == ApiExceptionType.response &&
          (statusCode == 429 ||
              (statusCode != null &&
                  statusCode >= 500 &&
                  statusCode <= 599)))) {
    return const CustomerFeatureReadTimeoutFailure();
  }
  if (statusCode == 401 || statusCode == 403) {
    return const CustomerFeatureForbiddenFailure();
  }
  if (mapBadRequestToRejected && (statusCode == 400 || statusCode == 422)) {
    return const CustomerFeatureRejectedFailure();
  }
  return const CustomerFeatureInvalidDataFailure();
}

CustomerOrderFailure mapCustomerOrderCreateApiException(ApiException error) {
  if (error.type == ApiExceptionType.response && error.hasBackendErrorCode) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const CustomerOrderForbiddenFailure();
    }
    if (error.code == 'PRICE_CHANGED') {
      return const CustomerOrderPriceChangedFailure();
    }
    if (error.code == 'ORDER_REJECTED' ||
        error.code == 'STALL_CLOSED' ||
        error.code == 'MENU_UNAVAILABLE' ||
        error.statusCode == 400 ||
        error.statusCode == 404 ||
        error.statusCode == 409 ||
        error.statusCode == 422) {
      return const CustomerOrderRejectedFailure();
    }
  }
  return const CustomerOrderUnconfirmedFailure();
}

CanteenApplicationFailure mapCanteenApplicationSubmitApiException(
  ApiException error,
) {
  if (error.type == ApiExceptionType.response && error.hasBackendErrorCode) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const CanteenApplicationForbiddenFailure();
    }
    if (error.statusCode == 409 || error.code == 'VERSION_CONFLICT') {
      return const CanteenApplicationConflictFailure();
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return const CanteenApplicationRejectedFailure();
    }
  }
  return const CanteenApplicationUnconfirmedFailure();
}

CustomerOrderCancellationFailure mapCustomerOrderCancellationApiException(
  ApiException error,
) {
  if (error.type == ApiExceptionType.response && error.hasBackendErrorCode) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const CustomerOrderCancellationForbiddenFailure();
    }
    if (error.statusCode == 409 || error.code == 'VERSION_CONFLICT') {
      return const CustomerOrderCancellationConflictFailure();
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return const CustomerOrderCancellationRejectedFailure();
    }
  }
  return const CustomerOrderCancellationUnknownFailure();
}

FoodPreferencesFailure mapFoodPreferencesReadApiException(ApiException error) {
  final statusCode = error.statusCode;
  if (error.type == ApiExceptionType.timeout ||
      error.type == ApiExceptionType.connection ||
      (error.type == ApiExceptionType.response &&
          (statusCode == 429 ||
              (statusCode != null &&
                  statusCode >= 500 &&
                  statusCode <= 599)))) {
    return const FoodPreferencesReadTimeoutFailure();
  }
  if (statusCode == 401 || statusCode == 403) {
    return const FoodPreferencesForbiddenFailure();
  }
  return const FoodPreferencesInvalidDataFailure();
}

FoodPreferencesFailure mapFoodPreferencesSaveApiException(ApiException error) {
  if (error.type == ApiExceptionType.response && error.hasBackendErrorCode) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const FoodPreferencesForbiddenFailure();
    }
    if (error.statusCode == 409 || error.code == 'VERSION_CONFLICT') {
      return const FoodPreferencesConflictFailure();
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return const FoodPreferencesRejectedFailure();
    }
  }
  return const FoodPreferencesUnknownFailure();
}
