import '../../entities/base/repo.dart';
import '../base.dart';
import 'endpoint_enums.dart';

class CMS {
  static Future<dynamic> getHomeBanner() async {
    return NetworkConnector.callEndpoint(
        CMSEndpoints.getHomeBanner as Endpoint, {});
  }

  static Future<dynamic> getPlanFooter() async {
    return NetworkConnector.callEndpoint(
        CMSEndpoints.getPlanFooter as Endpoint, {});
  }

  static Future<dynamic> getTutorials({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
        repo, CMSEndpoints.getTutorials as Endpoint, {});
  }

  static Future<dynamic> getTutorialInfo({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
        repo, CMSEndpoints.getTutorialInfo as Endpoint, {});
  }

  static Future<dynamic> getTutorialData({required String title}) async {
    return NetworkConnector.callEndpoint(
        CMSEndpoints.getTutorialData as Endpoint, {'title': title});
  }
}
