using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace routent.AdminAPI.DTOs.Auth;

public class RefreshTokenRequestDto
{
    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}

public class ChangePasswordRequestDto
{
    [Required]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    public string NewPassword { get; set; } = string.Empty;
}

public class Verify2FARequestDto
{
    [Required]
    [StringLength(12)]
    public string Totp { get; set; } = string.Empty;
}

public class ForgotPasswordRequestDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
}

public class ResetPasswordRequestDto
{
    [Required]
    public string Token { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    public string NewPassword { get; set; } = string.Empty;
}

public class VerifyOtpRequestDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [StringLength(12, MinimumLength = 6)]
    public string Otp { get; set; } = string.Empty;
}

public class ExternalLoginRequestDto
{
    [Required]
    public string Token { get; set; } = string.Empty;

    [StringLength(200)]
    public string? FullName { get; set; }
}

public class UserRegisterRequestDto
{
    [Required]
    [StringLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string LastName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    public string Password { get; set; } = string.Empty;
}

public class KeeperRegisterRequestDto
{
    [Required]
    [StringLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string LastName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    public string Password { get; set; } = string.Empty;

    [Required]
    [StringLength(200)]
    public string BusinessName { get; set; } = string.Empty;

    public string? SubmissionIntent { get; set; }

    [StringLength(200)]
    public string? BusinessLicense { get; set; }

    public string? IdentityProofType { get; set; }
    public string? IdentityProofNumber { get; set; }
    public IFormFile? IdentityProofImage { get; set; }

    public string? BusinessLicenseNumber { get; set; }
    public IFormFile? BusinessLicenseImage { get; set; }

    public IFormFile? GstCertificateImage { get; set; }

    public IFormFile? PanCardImage { get; set; }

    public string? AddressProofType { get; set; }
    public IFormFile? AddressProofImage { get; set; }

    public IFormFile? ShopFrontImage { get; set; }
    public IFormFile? ShopInsideImage { get; set; }
}

public class UserLoginRequestDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    public string Password { get; set; } = string.Empty;
}

public class OtpValidationResponseDto
{
    public string ResetToken { get; set; } = string.Empty;
}

public class Setup2FAResponseDto
{
    public string Secret { get; set; } = string.Empty;
    public string QrUri { get; set; } = string.Empty;
}

public class UserLoginResponseDto
{
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public int ExpiresIn { get; set; }
    public string Role { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string? FirebaseToken { get; set; }
}
