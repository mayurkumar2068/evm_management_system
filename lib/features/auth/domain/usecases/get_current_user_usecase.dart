import 'package:MPSECNET/core/error/result.dart';
import 'package:MPSECNET/core/usecase/usecase.dart';
import 'package:MPSECNET/features/auth/domain/entities/auth_user.dart';
import 'package:MPSECNET/features/auth/domain/repository/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<AuthUser, NoParams> {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(NoParams params) => _repository.currentUser();
}
