import 'package:evm_management_system/core/error/failure.dart';
import 'package:evm_management_system/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('success holds a value and folds onSuccess', () {
      const Result<int> result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 42);
      final String folded = result.fold(
        onSuccess: (int v) => 'v=$v',
        onFailure: (_) => 'fail',
      );
      expect(folded, 'v=42');
    });

    test('failure holds a Failure and folds onFailure', () {
      const Result<int> result = Result<int>.failure(NetworkFailure());
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('map transforms success and preserves failure', () {
      const Result<int> ok = Result<int>.success(2);
      expect(ok.map((int v) => v * 10).valueOrNull, 20);

      const Result<int> err = Result<int>.failure(UnknownFailure());
      expect(err.map((int v) => v * 10).failureOrNull, isA<UnknownFailure>());
    });
  });
}
