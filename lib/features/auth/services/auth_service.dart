import 'dart:io' if (dart.library.html) 'package:note_sync/utils/web_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:note_sync/utils/config_service.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  final FlutterAppAuth? _appAuth = kIsWeb ? null : const FlutterAppAuth();

  static const _tokenKey = 'oauth_access_token';
  static const _refreshTokenKey = 'oauth_refresh_token';
  static const _expirationKey = 'oauth_expiration';

  final FlutterSecureStorage _secureStorage;
  final ConfigService _configService;

  static final List<String> _scopes = [
    drive.DriveApi.driveFileScope,
    'email',
    'profile',
  ];

  String get _redirectUri {
    if (kIsWeb) {
      return 'http://localhost:8080/auth-callback';
    } else if (Platform.isAndroid) {
      return 'com.googleusercontent.apps.585188810936-5hs49kuoii16ffoj9u4ossg6vgdhfqvc:/oauth2redirect';
    } else if (Platform.isIOS) {
      return 'com.googleusercontent.apps.585188810936-5nde3djan2osb40e8nc7ubq6vdg1jgih:/oauth2redirect';
    } else {
      return 'http://localhost:8080/auth-callback';
    }
  }

  AuthService({
    FlutterSecureStorage? secureStorage,
    ConfigService? configService,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _configService = configService ?? ConfigService();

  Future<bool> _checkNetworkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Network connectivity check failed: $e');
      return false;
    }
  }

  Future<void> _saveCredentials(AccessCredentials credentials) async {
    try {
      await _secureStorage.write(
        key: _tokenKey,
        value: credentials.accessToken.data,
      );

      await _secureStorage.write(
        key: _expirationKey,
        value: credentials.accessToken.expiry.toIso8601String(),
      );

      if (credentials.refreshToken != null) {
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: credentials.refreshToken,
        );
      } else {
        await _secureStorage.delete(key: _refreshTokenKey);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Future<AccessCredentials?> signIn() async {
    final hasConnection = await _checkNetworkConnectivity();
    if (!hasConnection) {
      debugPrint('No network connection available');
      throw Exception('No network connection available');
    }

    try {
      if (kIsWeb || Platform.isIOS || Platform.isAndroid) {
        return await _signInWithGoogleSignIn();
      } else if (!kIsWeb) {
        return await _signInWithAppAuth();
      } else {
        throw Exception('No authentication method available for this platform');
      }
    } catch (e) {
      debugPrint('Error during sign in: $e');
      await signOut();
      rethrow;
    }
  }

  Future<AccessCredentials?> _signInWithGoogleSignIn() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-in was canceled by user');
        return null;
      }

      debugPrint('Successfully signed in as: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      debugPrint('Successfully obtained authentication tokens');

      final accessToken = AccessToken(
        'Bearer',
        googleAuth.accessToken!,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      final credentials = AccessCredentials(
        accessToken,
        googleAuth.serverAuthCode,
        _scopes,
      );

      await _saveCredentials(credentials);
      debugPrint('Successfully signed in with Google Sign-In');
      return credentials;
    } catch (e) {
      debugPrint('Error in GoogleSignIn: $e');

      rethrow;
    }
  }

  Future<AccessCredentials?> _signInWithAppAuth() async {
    try {
      final clientId = await _configService.getClientId();

      final AuthorizationTokenRequest tokenRequest = AuthorizationTokenRequest(
        clientId,
        _redirectUri,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: 'https://accounts.google.com/o/oauth2/auth',
          tokenEndpoint: 'https://oauth2.googleapis.com/token',
        ),
        scopes: [
          'openid',
          'email',
          'profile',
          drive.DriveApi.driveFileScope,
        ],
      );

      final AuthorizationTokenResponse? result =
          await _appAuth?.authorizeAndExchangeCode(tokenRequest);

      if (result == null || result.accessToken == null) {
        debugPrint('Authorization failed or was canceled');
        return null;
      }

      final accessToken = AccessToken(
        'Bearer',
        result.accessToken!,
        result.accessTokenExpirationDateTime ??
            DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      final credentials = AccessCredentials(
        accessToken,
        result.refreshToken,
        _scopes,
      );

      await _saveCredentials(credentials);
      debugPrint('Successfully signed in with AppAuth');
      return credentials;
    } catch (e) {
      debugPrint('Error in AppAuth: $e');
      rethrow;
    }
  }

  Future<AccessCredentials?> getStoredCredentials() async {
    final accessTokenData = await _secureStorage.read(key: _tokenKey);
    final expiryString = await _secureStorage.read(key: _expirationKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

    if (accessTokenData == null || expiryString == null) {
      return null;
    }

    try {
      final accessToken = AccessToken(
        'Bearer',
        accessTokenData,
        DateTime.parse(expiryString),
      );

      return AccessCredentials(accessToken, refreshToken, _scopes);
    } catch (e) {
      debugPrint('Error retrieving stored credentials: $e');
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _expirationKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    final credentials = await getStoredCredentials();
    if (credentials == null) return false;
    return credentials.accessToken.expiry.isAfter(DateTime.now().toUtc());
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('GoogleSignIn signOut successful.');
    } catch (e) {
      debugPrint('Error signing out from GoogleSignIn: $e');
    }

    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _expirationKey);
      debugPrint('Local credentials cleared.');
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }

  Future<AccessCredentials?> refreshCredentialsIfNeeded() async {
    final credentials = await getStoredCredentials();

    if (credentials == null) {
      debugPrint('No stored credentials found for refresh.');
      return null;
    }

    final needsRefresh = credentials.accessToken.expiry
        .isBefore(DateTime.now().toUtc().add(const Duration(minutes: 5)));

    if (!needsRefresh) {
      debugPrint('Token does not need refresh.');
      return credentials;
    }

    debugPrint('Token needs refresh.');

    if (credentials.refreshToken == null) {
      debugPrint('No refresh token available. Requires re-authentication.');
      await signOut();
      return null;
    }

    debugPrint('Attempting token refresh using AppAuth.');
    try {
      final clientId = await _configService.getClientId();

      final TokenResponse? result = await _appAuth?.token(
        TokenRequest(
          clientId,
          _redirectUri,
          refreshToken: credentials.refreshToken,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: 'https://accounts.google.com/o/oauth2/auth',
            tokenEndpoint: 'https://oauth2.googleapis.com/token',
          ),
          scopes: [
            'openid',
            'https://www.googleapis.com/auth/userinfo.email',
            'https://www.googleapis.com/auth/userinfo.profile',
            'https://www.googleapis.com/auth/drive.file',
          ],
        ),
      );

      if (result != null && result.accessToken != null) {
        debugPrint('Token refresh successful.');
        final accessToken = AccessToken(
          'Bearer',
          result.accessToken!,
          result.accessTokenExpirationDateTime ??
              DateTime.now().toUtc().add(const Duration(hours: 1)),
        );

        final newCredentials = AccessCredentials(
          accessToken,
          result.refreshToken ?? credentials.refreshToken,
          _scopes,
        );

        await _saveCredentials(newCredentials);
        return newCredentials;
      } else {
        debugPrint(
            'Token refresh failed: AppAuth returned null result or no access token.');
        await signOut();
        return null;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      await signOut();
      return null;
    }
  }
}
