import 'package:muntum/utils/apple_identity_diagnostics.dart';

String? appleIdentitySubject(String identityToken) =>
    appleIdentityDiagnostics(identityToken)?.sub;
