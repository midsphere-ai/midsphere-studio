import 'package:flutter_client/logics/data/helpers/general_utils.dart';

import '../../entities/cms/tutorial_blog.dart';
import '../base.dart';

enum CMSEndpoints implements Endpoint {
  getHomeBanner,
  getTutorials,
  getTutorialInfo,
  getPlanFooter,
  getTutorialData;

  @override
  String get value => "cms/${Toolkit.camelToSnakeCase(toString().split('.').last)}";

  @override
  String get name => "cms/";

  @override
  APIReference get requiredParams {
    switch (this) {
      case CMSEndpoints.getHomeBanner:
        return APIReference(
          endpoint: '/home-banner',
          method: 'GET',
          parameters: [],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

      case CMSEndpoints.getTutorials:
        return APIReference(
          endpoint: '/tutorials',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, TutorialBlog.fromJson],
        );

      case CMSEndpoints.getTutorialInfo:
        return APIReference(
          endpoint: '/tutorials/info',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, TutorialBlog.fromJson],
        );

      case CMSEndpoints.getPlanFooter:
        return APIReference(
          endpoint: '/plan-footer',
          method: 'GET',
          parameters: [],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

      case CMSEndpoints.getTutorialData:
        return APIReference(
          endpoint: '/tutorials/content',
          method: 'GET',
          parameters: ['title'],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );
    }
  }
}
