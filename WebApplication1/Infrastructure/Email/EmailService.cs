using SendGrid;
using SendGrid.Helpers.Mail;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;
    private readonly ISendGridClient _client;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
        _client = new SendGridClient(_configuration["EmailSettings:SendGridApiKey"]);
    }

    public async Task SendOtpEmailAsync(string email, string otp)
    {
        var from = new EmailAddress(
            _configuration["EmailSettings:FromEmail"], 
            _configuration["EmailSettings:FromName"]);
        var to = new EmailAddress(email);
        var subject = "Your Verification Code";
        var plainTextContent = $"Your verification code is: {otp}. It will expire in 5 minutes.";
        var htmlContent = $"<strong>Your verification code is: {otp}</strong><br>It will expire in 5 minutes.";
        var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);
        
        var response = await _client.SendEmailAsync(msg);
        
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Body.ReadAsStringAsync();
            _logger.LogError("Failed to send OTP email to {Email}. Status: {Status}. Error: {Error}", 
                email, response.StatusCode, body);
        }
        else
        {
            _logger.LogInformation("Sent OTP email to {Email}", email);
        }
    }

    public async Task SendPasswordResetEmailAsync(string email, string token)
    {
        var from = new EmailAddress(
            _configuration["EmailSettings:FromEmail"], 
            _configuration["EmailSettings:FromName"]);
        var to = new EmailAddress(email);
        var subject = "Password Reset Request";
        var plainTextContent = $"Your password reset token is: {token}. It will expire in 15 minutes.";
        var htmlContent = $"<strong>Your password reset token is: {token}</strong><br>It will expire in 15 minutes.";
        var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);
        
        var response = await _client.SendEmailAsync(msg);
        
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Body.ReadAsStringAsync();
            _logger.LogError("Failed to send password reset email to {Email}. Status: {Status}. Error: {Error}", 
                email, response.StatusCode, body);
        }
        else
        {
            _logger.LogInformation("Sent password reset email to {Email}", email);
        }
    }
}
