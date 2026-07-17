import 'package:evm_management_system/features/auth/data/models/user_model.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/domain/entities/user_role.dart';

/// Translates between [UserModel] (data) and [AuthUser] (domain).
abstract final class UserMapper {
  static AuthUser toEntity(UserModel model) => AuthUser(
    id: model.id,
    officerId: model.officerId,
    fullName: model.fullName,
    role: UserRole.fromString(model.role),
    email: model.email,
    designation: model.designation,
    stateCode: model.stateCode,
    districtCode: model.districtCode,
    electionId: model.electionId,
    psId: model.psId,
    areaType: model.areaType,
    pollingStationCode: model.pollingStationCode,
    pollingStationName: model.pollingStationName,
  );

  static UserModel fromEntity(AuthUser user) => UserModel(
    id: user.id,
    officerId: user.officerId,
    fullName: user.fullName,
    role: user.role.name,
    email: user.email,
    designation: user.designation,
    stateCode: user.stateCode,
    districtCode: user.districtCode,
    electionId: user.electionId,
    psId: user.psId,
    areaType: user.areaType,
    pollingStationCode: user.pollingStationCode,
    pollingStationName: user.pollingStationName,
  );
}
