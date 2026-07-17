import 'package:dio/dio.dart';
import 'package:evm_management_system/core/error/error_mapper.dart';
import 'package:evm_management_system/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final RequestOptions options = RequestOptions(path: '/test');

  DioException withStatus(int code) => DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: code),
  );

  group('ErrorMapper', () {
    test('maps 401 to UnauthorizedFailure', () {
      expect(ErrorMapper.map(withStatus(401)), isA<UnauthorizedFailure>());
    });
    test('maps 403 to ForbiddenFailure', () {
      expect(ErrorMapper.map(withStatus(403)), isA<ForbiddenFailure>());
    });
    test('maps 404 to NotFoundFailure', () {
      expect(ErrorMapper.map(withStatus(404)), isA<NotFoundFailure>());
    });
    test('maps 422 to ValidationFailure', () {
      expect(ErrorMapper.map(withStatus(422)), isA<ValidationFailure>());
    });
    test('maps 500 to ApiFailure', () {
      expect(ErrorMapper.map(withStatus(500)), isA<ApiFailure>());
    });
    test('maps connection timeout to NetworkFailure', () {
      final DioException e = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
      expect(ErrorMapper.map(e), isA<NetworkFailure>());
    });
  });
}
