import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/features/dashboard/data/dashboard_card_mapper.dart';
import 'package:evm_management_system/features/dashboard/data/models/dashboard_card_model.dart';
import 'package:evm_management_system/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardCardModel', () {
    test('parses card-list envelope row with HI/EN fields', () {
      final DashboardCardModel card = DashboardCardModel.fromJson(
        <String, dynamic>{
          'ID': 5,
          'CategoryName': 'निर्वाचन संबंधी सेवाऍं',
          'CategoryNameEn': 'Election Services',
          'CardName': 'पीठासीन अधिकारी',
          'CardNameEn': 'Presiding Officer',
          'IsRegistrationAllowed': true,
          'IsLogin': true,
          'IsWebView': false,
          'Url': null,
          'IsActive': true,
        },
      );

      expect(card.id, 5);
      expect(card.isLogin, isTrue);
      expect(card.isRegistrationAllowed, isTrue);
      expect(card.displayName(preferHindi: true), 'पीठासीन अधिकारी');
      expect(card.displayName(preferHindi: false), 'Presiding Officer');
      expect(
        card.displayCategory(preferHindi: false),
        'Election Services',
      );
    });

    test('filters inactive via isActive flag', () {
      final DashboardCardModel inactive = DashboardCardModel.fromJson(
        <String, dynamic>{
          'ID': 3,
          'CategoryNameEn': 'Election Services',
          'CardNameEn': 'Election Expenditure',
          'IsActive': false,
          'IsWebView': true,
          'Url': 'https://example.com',
        },
      );
      expect(inactive.isActive, isFalse);
    });
  });

  group('DashboardCardMapper', () {
    const List<DashboardCardModel> sample = <DashboardCardModel>[
      DashboardCardModel(
        id: 1,
        categoryName: 'मतदाता सेवाऍं',
        categoryNameEn: 'Voter Services',
        cardName: 'दावा-आपत्ति आवेदन',
        cardNameEn: 'Claims & Objections Application',
        isRegistrationAllowed: false,
        isLogin: false,
        isWebView: true,
        url: 'https://mpsecerms.mp.gov.in/secforms',
        isActive: true,
      ),
      DashboardCardModel(
        id: 2,
        categoryName: 'मतदाता सेवाऍं',
        categoryNameEn: 'Voter Services',
        cardName: 'मतदाता खोजें',
        cardNameEn: 'Voter Search',
        isRegistrationAllowed: false,
        isLogin: false,
        isWebView: false,
        url: null,
        isActive: true,
      ),
      DashboardCardModel(
        id: 4,
        categoryName: 'निर्वाचन संबंधी सेवाऍं',
        categoryNameEn: 'Election Services',
        cardName: 'मतदान केन्द्र सर्वे',
        cardNameEn: 'Polling Station Survey',
        isRegistrationAllowed: true,
        isLogin: true,
        isWebView: false,
        url: null,
        isActive: true,
      ),
      DashboardCardModel(
        id: 5,
        categoryName: 'निर्वाचन संबंधी सेवाऍं',
        categoryNameEn: 'Election Services',
        cardName: 'पीठासीन अधिकारी',
        cardNameEn: 'Presiding Officer',
        isRegistrationAllowed: true,
        isLogin: true,
        isWebView: false,
        url: null,
        isActive: true,
      ),
    ];

    test('maps native routes and login kinds without breaking flows', () {
      final List<DashboardService> services = DashboardCardMapper.mapServices(
        cards: sample,
        preferHindi: false,
        surveyWebUrl: 'https://survey.example/',
        voterRegistrationUrl: 'https://reg.example/',
        expenditureUrl: 'https://exp.example/',
      );

      expect(services, hasLength(4));

      final DashboardService claims = services.firstWhere(
        (DashboardService s) => s.title.contains('Claims'),
      );
      expect(claims.openAsExternalPortal, isTrue);
      expect(claims.requiresServiceLogin, isFalse);
      expect(claims.url, contains('secforms'));

      final DashboardService search = services.firstWhere(
        (DashboardService s) => s.title == 'Voter Search',
      );
      expect(search.routeName, AppRoute.voterSearch.path);
      expect(search.requiresServiceLogin, isFalse);

      final DashboardService survey = services.firstWhere(
        (DashboardService s) => s.title.contains('Survey'),
      );
      expect(survey.requiredLoginKind, ServiceLoginKind.survey);
      expect(survey.requiresServiceLogin, isTrue);
      expect(survey.registrationAllowed, isTrue);
      expect(survey.url, 'https://survey.example/');

      final DashboardService po = services.firstWhere(
        (DashboardService s) => s.title == 'Presiding Officer',
      );
      expect(po.requiredLoginKind, ServiceLoginKind.presiding);
      expect(po.routeName, AppRoute.presidingDashboard.path);
      expect(po.registrationAllowed, isTrue);
    });

    test('uses Hindi titles when preferHindi is true', () {
      final List<DashboardService> services = DashboardCardMapper.mapServices(
        cards: sample,
        preferHindi: true,
        surveyWebUrl: 'https://survey.example/',
        voterRegistrationUrl: 'https://reg.example/',
        expenditureUrl: 'https://exp.example/',
      );
      expect(services.any((DashboardService s) => s.title == 'मतदाता खोजें'), isTrue);
      expect(
        services.any((DashboardService s) => s.title == 'पीठासीन अधिकारी'),
        isTrue,
      );
    });

    test('resolves category labels from API', () {
      expect(
        DashboardCardMapper.categoryLabel(
          cards: sample,
          category: DashboardCategory.voterServices,
          preferHindi: false,
        ),
        'Voter Services',
      );
      expect(
        DashboardCardMapper.categoryLabel(
          cards: sample,
          category: DashboardCategory.aboutElections,
          preferHindi: true,
        ),
        'निर्वाचन संबंधी सेवाऍं',
      );
    });
  });
}
