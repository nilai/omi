import 'package:envied/envied.dart';
import 'env.dart';

@Envied(allowOptionalFields: true, path: '.dev.env')
final class DevEnv implements EnvFields {
  DevEnv();

  @override
  @EnviedField(varName: 'OPENAI_API_KEY', obfuscate: true)
  final String? openAIAPIKey = _DevEnv.openAIAPIKey;

  @override
  @EnviedField(varName: 'MIXPANEL_PROJECT_TOKEN', obfuscate: true)
  final String? mixpanelProjectToken = _DevEnv.mixpanelProjectToken;

  @override
  @EnviedField(varName: 'API_BASE_URL', obfuscate: true)
  final String? apiBaseUrl = _DevEnv.apiBaseUrl;

  @override
  @EnviedField(varName: 'NOTE_BASE_URL', obfuscate: true)
  final String? noteBaseUrl = _DevEnv.noteBaseUrl;

  @override
  @EnviedField(varName: 'GROWTHBOOK_API_KEY', obfuscate: true)
  final String? growthbookApiKey = _DevEnv.growthbookApiKey;

  @override
  @EnviedField(varName: 'GOOGLE_MAPS_API_KEY', obfuscate: true)
  final String? googleMapsApiKey = _DevEnv.googleMapsApiKey;

  @override
  @EnviedField(varName: 'INTERCOM_APP_ID', obfuscate: true)
  final String? intercomAppId = _DevEnv.intercomAppId;

  @override
  @EnviedField(varName: 'INTERCOM_IOS_API_KEY', obfuscate: true)
  final String? intercomIOSApiKey = _DevEnv.intercomIOSApiKey;

  @override
  @EnviedField(varName: 'INTERCOM_ANDROID_API_KEY', obfuscate: true)
  final String? intercomAndroidApiKey = _DevEnv.intercomAndroidApiKey;

  @override
  @EnviedField(varName: 'GOOGLE_CLIENT_ID', obfuscate: true)
  final String? googleClientId = _DevEnv.googleClientId;

  @override
  @EnviedField(varName: 'GOOGLE_CLIENT_SECRET', obfuscate: true)
  final String? googleClientSecret = _DevEnv.googleClientSecret;

  @override
  @EnviedField(varName: 'USE_WEB_AUTH', obfuscate: false, defaultValue: false)
  final bool? useWebAuth = _DevEnv.useWebAuth;

  @override
  @EnviedField(varName: 'USE_AUTH_CUSTOM_TOKEN', obfuscate: false, defaultValue: false)
  final bool? useAuthCustomToken = _DevEnv.useAuthCustomToken;

  @override
  @EnviedField(varName: 'AUTH_TOKEN', obfuscate: true)
  final String? authToken = _DevEnv.authToken;
}

// coverage:ignore-file
// ignore_for_file: type=lint
// generated_from: .dev.env
final class _DevEnv {
  static final String? openAIAPIKey = null;

  static final String? mixpanelProjectToken = null;

  static const List<int> _enviedkeyapiBaseUrl = <int>[
    3007903828,
    558811251,
    2984951531,
    1521587089,
    2976671840,
    1706442590,
    1417502972,
    1630302808,
    3854081127,
    1844360963,
    2533989220,
    3311519190,
    1888892355,
    1866415450,
    3312716313,
    490183105,
    3289153163,
    3820679395,
    3610454600,
    4063332987,
    283470179,
    2563314806,
    3852807703,
  ];

  static const List<int> _envieddataapiBaseUrl = <int>[
    3007903804,
    558811143,
    2984951455,
    1521587169,
    2976671763,
    1706442596,
    1417502931,
    1630302839,
    3854081030,
    1844361075,
    2533989133,
    3311519224,
    1888892332,
    1866415415,
    3312716400,
    490183072,
    3289153275,
    3820679306,
    3610454630,
    4063332888,
    283470092,
    2563314715,
    3852807736,
  ];

  // static final String? apiBaseUrl = String.fromCharCodes(List<int>.generate(
  //   _envieddataapiBaseUrl.length,
  //   (int i) => i,
  //   growable: false,
  // ).map((int i) => _envieddataapiBaseUrl[i] ^ _enviedkeyapiBaseUrl[i]));

  static final String? apiBaseUrl = 'https://meetsummertech.com/';

  static final String? noteBaseUrl = null;

  static final String? growthbookApiKey = null;

  static final String? googleMapsApiKey = null;

  static final String? intercomAppId = null;

  static final String? intercomIOSApiKey = null;

  static final String? intercomAndroidApiKey = null;

  static final String? googleClientId = null;

  static final String? googleClientSecret = null;

  static const bool? useWebAuth = true;

  static const bool? useAuthCustomToken = true;

  static final String? authToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiAiMTgiLCAiZGV2aWNlX2lkIjogIjExMTExMTExIiwgImlhdCI6IDE3NzQ5NzcxMzcsICJleHAiOiAxNzc3NTY5MTM3fQ.r7QWpUTVt9uJMR2-lwJwlb6S5pkug0EIALTpLBO-Ci8';
}