import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:animus/constants/env.dart';
import 'package:animus/core/auth/interfaces/google_auth_driver.dart';

class GoogleSignInGoogleAuthDriver implements GoogleAuthDriver {
  final GoogleSignIn _googleSignIn;

  const GoogleSignInGoogleAuthDriver({required GoogleSignIn googleSignIn})
    : _googleSignIn = googleSignIn;

  @override
  Future<String?> requestIdToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final GoogleSignInAuthentication authentication =
          await account.authentication;
      final String? idToken = authentication.idToken?.trim();

      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google Sign-In did not return an idToken.');
      }

      return idToken;
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_canceled') {
        return null;
      }

      rethrow;
    }
  }
}

final Provider<GoogleAuthDriver> googleAuthDriverProvider =
    Provider<GoogleAuthDriver>((Ref ref) {
      return GoogleSignInGoogleAuthDriver(
        googleSignIn: GoogleSignIn(
          scopes: const ['email'],
          serverClientId: Env.googleServerClientId,
        ),
      );
    });
