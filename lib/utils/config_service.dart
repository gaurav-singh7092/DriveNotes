import 'dart:io' if (dart.library.html) 'package:note_sync/utils/web_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class ConfigService {
  static const String _webClientIdKey = 'auth_web_client_id';
  static const String _androidClientIdKey = 'auth_android_client_id';
  static const String _iosClientIdKey = 'auth_ios_client_id';
  static const String _defaultClientIdKey = 'auth_default_client_id';

  final FlutterSecureStorage _secureStorage;
  bool _initialized = false;

  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService({FlutterSecureStorage? secureStorage}) {
    if (secureStorage != null) {
      return ConfigService._withStorage(secureStorage);
    }
    return _instance;
  }

  ConfigService._internal() : _secureStorage = const FlutterSecureStorage();

  ConfigService._withStorage(FlutterSecureStorage storage)
      : _secureStorage = storage;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final hasStoredConfig = await _hasStoredClientIds();

      if (!hasStoredConfig) {
        await _loadAndStoreInitialConfig();
      }

      _initialized = true;
      debugPrint('ConfigService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ConfigService: $e');
    }
  }

  Future<bool> _hasStoredClientIds() async {
    try {
      final webClientId = await _secureStorage.read(key: _webClientIdKey);
      return webClientId != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadAndStoreInitialConfig() async {
    try {
      final configJson = await rootBundle.loadString('assets/config.json');
      final config = json.decode(configJson);

      await _secureStorage.write(
        key: _webClientIdKey,
        value: config['webClientId'],
      );

      await _secureStorage.write(
        key: _androidClientIdKey,
        value: config['androidClientId'],
      );

      await _secureStorage.write(
        key: _iosClientIdKey,
        value: config['iosClientId'],
      );

      await _secureStorage.write(
        key: _defaultClientIdKey,
        value: config['defaultClientId'],
      );
    } catch (e) {
      debugPrint('Error loading initial configuration: $e');

      await _secureStorage.write(
        key: _webClientIdKey,
        value:
            '585188810936-m5bgmo1j7mbnl76h74fgf3rjk9vnodos.apps.googleusercontent.com',
      );

      await _secureStorage.write(
        key: _androidClientIdKey,
        value:
            '585188810936-5hs49kuoii16ffoj9u4ossg6vgdhfqvc.apps.googleusercontent.com',
      );

      await _secureStorage.write(
        key: _iosClientIdKey,
        value:
            '585188810936-5nde3djan2osb40e8nc7ubq6vdg1jgih.apps.googleusercontent.com',
      );

      await _secureStorage.write(
        key: _defaultClientIdKey,
        value:
            '585188810936-5hs49kuoii16ffoj9u4ossg6vgdhfqvc.apps.googleusercontent.com',
      );
    }
  }

  Future<String> getClientId() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      if (kIsWeb) {
        final webClientId = await _secureStorage.read(key: _webClientIdKey);
        if (webClientId != null) return webClientId;
      } else if (Platform.isAndroid) {
        final androidClientId =
            await _secureStorage.read(key: _androidClientIdKey);
        if (androidClientId != null) return androidClientId;
      } else if (Platform.isIOS) {
        final iosClientId = await _secureStorage.read(key: _iosClientIdKey);
        if (iosClientId != null) return iosClientId;
      }

      final defaultClientId =
          await _secureStorage.read(key: _defaultClientIdKey);
      if (defaultClientId != null) {
        return defaultClientId;
      }

      throw Exception('No client ID available');
    } catch (e) {
      debugPrint('Error retrieving client ID: $e');
      rethrow;
    }
  }

  Future<void> updateClientId(String platform, String newClientId) async {
    String key;

    switch (platform) {
      case 'web':
        key = _webClientIdKey;
        break;
      case 'android':
        key = _androidClientIdKey;
        break;
      case 'ios':
        key = _iosClientIdKey;
        break;
      default:
        key = _defaultClientIdKey;
    }

    await _secureStorage.write(key: key, value: newClientId);
  }
}
