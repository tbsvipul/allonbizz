import '../../../../l10n/app_localizations.dart';

/// Utility to map API Authentication and validation errors to localized user-friendly messages.
class AuthErrorMapper {
  static String getMessage(String? code, AppLocalizations l10n) {
    if (code == null) return l10n.authFailed;

    final normalized = code.trim();
    final lowered = normalized.toLowerCase();

    if (normalized.contains(' ')) return normalized;

    switch (lowered) {
      case 'user-not-found':
        return l10n.authUserNotFound;
      case 'invalid-email':
        return l10n.emailValidError;
      case 'unauthorized':
      case 'invalid credentials':
      case 'invalid-credential':
      case 'wrong-password':
        return l10n.authInvalidCredential;
      case 'email-already-in-use':
      case 'unprocessable_entity':
        return l10n.authEmailAlreadyInUse;
      case 'validation-error':
      case 'validation_error':
        return normalized.length > 20 ? normalized : l10n.authFailed;
      case 'network-request-failed':
      case 'network':
        return l10n.noInternet;
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This authentication method is not enabled.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'forgot-password-failed':
        return 'We could not send the reset OTP right now.';
      case 'invalid-otp':
        return 'The OTP is invalid or expired.';
      case 'reset-password-failed':
        return 'We could not reset the password right now.';
      case 'change-password-failed':
        return 'We could not change the password right now.';
      case 'requires-recent-login':
        return 'This sensitive operation requires a recent login. Please log in again.';
      default:
        if (lowered.contains('current password is incorrect')) {
          return 'Current password is incorrect.';
        }
        if (lowered.contains('different from the current password')) {
          return 'New password must be different from your current password.';
        }
        if (lowered.contains('expired otp') ||
            lowered.contains('expired password reset token')) {
          return 'The reset code has expired. Please request a new one.';
        }
        if (lowered.contains('email is already taken') ||
            lowered.contains('already registered')) {
          return l10n.authEmailAlreadyInUse;
        }
        if (lowered.contains('invalid') || lowered.contains('unauthorized')) {
          return l10n.authInvalidCredential;
        }
        return l10n.authFailed;
    }
  }
}
