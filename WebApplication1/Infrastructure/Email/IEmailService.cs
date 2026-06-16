namespace routent.AdminAPI.Services.Interfaces;

public interface IEmailService
{
    Task SendOtpEmailAsync(string email, string otp);
    Task SendPasswordResetEmailAsync(string email, string token);
    Task SendPasswordChangedNotificationEmailAsync(string email);
    Task SendAccountSuspensionEmailAsync(string email, string reason, string supportEmail);
}
