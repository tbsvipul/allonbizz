using OtpNet;

namespace allonbiz.AdminAPI.Helpers;

public static class TotpHelper
{
    public static string GenerateSecret()
    {
        var key = KeyGeneration.GenerateRandomKey(20);
        return Base32Encoding.ToString(key);
    }

    public static string GenerateQrUri(string secret, string email, string issuer = "allonbiz Admin")
    {
        return $"otpauth://totp/{issuer}:{email}?secret={secret}&issuer={issuer}&digits=6&period=30";
    }

    public static bool ValidateTotp(string secret, string totp)
    {
        var keyBytes = Base32Encoding.ToBytes(secret);
        var otpInstance = new Totp(keyBytes);
        return otpInstance.VerifyTotp(totp, out _, new VerificationWindow(previous: 1, future: 1));
    }
}
