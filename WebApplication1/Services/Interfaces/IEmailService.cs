namespace allonbiz.AdminAPI.Services.Interfaces;

public interface IEmailService
{
    Task SendOtpEmailAsync(string email, string otp);
    Task SendPasswordResetEmailAsync(string email, string token);
}
