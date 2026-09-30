import 'package:MPSECNET/core/di/app_services.dart';
import 'package:MPSECNET/core/network/po_election_api_client.dart';
import 'package:MPSECNET/features/grievance/data/datasources/grievance_remote_datasource.dart';
import 'package:MPSECNET/features/grievance/presentation/controllers/grievance_controller.dart';
import 'package:get/get.dart';

abstract final class GrievanceModule {
  static GrievanceRemoteDatasource? _datasource;

  static GrievanceRemoteDatasource get datasource {
    return _datasource ??= GrievanceRemoteDatasource(
      dio: PoElectionApiClient.instance(AppServices.config),
    );
  }

  static GrievanceController ensureController() {
    if (Get.isRegistered<GrievanceController>()) {
      return Get.find<GrievanceController>();
    }
    // permanent: true — the module spans two routes (OTP screen, then the
    // form screen after Get.off()). Without this, GetX's SmartManagement
    // ties the controller's lifecycle to the OTP route and deletes it
    // (disposing every TextEditingController it owns) the moment that
    // route is popped, even though the form screen still needs it.
    return Get.put(GrievanceController(datasource), permanent: true);
  }
}
