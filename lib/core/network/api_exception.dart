import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRateLimited;
  final bool isNoInternet;

  ApiException({
    required this.message,
    this.statusCode,
    this.isRateLimited = false,
    this.isNoInternet = false,
  });

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message:
              'Connection timed out. Please check your network connection.',
          isNoInternet: true,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message:
              'Unable to reach the photography server. Check your internet connection.',
          isNoInternet: true,
        );

      case DioExceptionType.badResponse:
        final status = dioException.response?.statusCode;
        if (status == 429) {
          return ApiException(
            message:
                'Pexels API rate limit reached. Please wait a moment and try again.',
            statusCode: status,
            isRateLimited: true,
          );
        } else if (status == 401 || status == 403) {
          return ApiException(
            message:
                'Invalid or missing Pexels API Key. Please verify .env configuration.',
            statusCode: status,
          );
        } else if (status == 404) {
          return ApiException(
            message: 'Requested photo or collection could not be found.',
            statusCode: status,
          );
        }
        return ApiException(
          message:
              dioException.response?.data?['error']?.toString() ??
              'Server responded with status $status. Please try again.',
          statusCode: status,
        );

      case DioExceptionType.cancel:
        return ApiException(message: 'Request was cancelled.');

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message:
              dioException.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  @override
  String toString() => message;
}
