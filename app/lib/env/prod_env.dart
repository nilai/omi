import 'package:envied/envied.dart';
import 'env.dart';

@Envied(allowOptionalFields: true, path: '.env')
final class ProdEnv implements EnvFields {
  ProdEnv();

  @override
  @EnviedField(varName: 'OPENAI_API_KEY', obfuscate: true)
  final String? openAIAPIKey = _ProdEnv.openAIAPIKey;

  @override
  @EnviedField(varName: 'MIXPANEL_PROJECT_TOKEN', obfuscate: true)
  final String? mixpanelProjectToken = _ProdEnv.mixpanelProjectToken;

  @override
  @EnviedField(varName: 'API_BASE_URL', obfuscate: true)
  final String? apiBaseUrl = _ProdEnv.apiBaseUrl;

  @override
  @EnviedField(varName: 'NOTE_BASE_URL', obfuscate: true)
  final String? noteBaseUrl = _ProdEnv.noteBaseUrl;

  @override
  @EnviedField(varName: 'GROWTHBOOK_API_KEY', obfuscate: true)
  final String? growthbookApiKey = _ProdEnv.growthbookApiKey;

  @override
  @EnviedField(varName: 'GOOGLE_MAPS_API_KEY', obfuscate: true)
  final String? googleMapsApiKey = _ProdEnv.googleMapsApiKey;

  @override
  @EnviedField(varName: 'INTERCOM_APP_ID', obfuscate: true)
  final String? intercomAppId = _ProdEnv.intercomAppId;

  @override
  @EnviedField(varName: 'INTERCOM_IOS_API_KEY', obfuscate: true)
  final String? intercomIOSApiKey = _ProdEnv.intercomIOSApiKey;

  @override
  @EnviedField(varName: 'INTERCOM_ANDROID_API_KEY', obfuscate: true)
  final String? intercomAndroidApiKey = _ProdEnv.intercomAndroidApiKey;

  @override
  @EnviedField(varName: 'GOOGLE_CLIENT_ID', obfuscate: true)
  final String? googleClientId = _ProdEnv.googleClientId;

  @override
  @EnviedField(varName: 'GOOGLE_CLIENT_SECRET', obfuscate: true)
  final String? googleClientSecret = _ProdEnv.googleClientSecret;

  @override
  @EnviedField(varName: 'USE_WEB_AUTH', obfuscate: false, defaultValue: false)
  final bool? useWebAuth = _ProdEnv.useWebAuth;

  @override
  @EnviedField(varName: 'USE_AUTH_CUSTOM_TOKEN', obfuscate: false, defaultValue: false)
  final bool? useAuthCustomToken = _ProdEnv.useAuthCustomToken;

  @override
  @EnviedField(varName: 'AUTH_TOKEN', obfuscate: true)
  final String? authToken = _ProdEnv.authToken;
}

final class _ProdEnv {
  static final String? openAIAPIKey = null;

  static final String? mixpanelProjectToken = null;

  static final String? apiBaseUrl = 'https://meetsummertech.com/';

  static final String? noteBaseUrl = null;

  static final String? growthbookApiKey = null;

  static final String? googleMapsApiKey = null;

  static final String? intercomAppId = null;

  static final String? intercomIOSApiKey = null;

  static final String? intercomAndroidApiKey = null;

  static final String? googleClientId = null;

  static final String? googleClientSecret = null;

  static const bool? useWebAuth = false;

  static const bool? useAuthCustomToken = false;

  static final String? authToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiAiMTgiLCAiZGV2aWNlX2lkIjogIjExMTExMTExIiwgImlhdCI6IDE3NzQ5NzcxMzcsICJleHAiOiAxNzc3NTY5MTM3fQ.r7QWpUTVt9uJMR2-lwJwlb6S5pkug0EIALTpLBO-Ci8';
}
