using SendGrid;
using SendGrid.Helpers.Mail;
using routent.AdminAPI.Services.Interfaces;
using System.Net;
using System.Net.Mail;

namespace routent.AdminAPI.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task SendOtpEmailAsync(string email, string otp)
    {
        var subject = "Your Verification Code";
        var plainTextContent = $"Your verification code is: {otp}. It will expire in 5 minutes.";
        var htmlContent = $"<strong>Your verification code is: {otp}</strong><br>It will expire in 5 minutes.";
        
        await SendEmailInternalAsync(email, subject, plainTextContent, htmlContent);
        
        // Log the OTP to the console for easier development testing
        _logger.LogInformation("DEVELOPMENT OTP for {Email}: {Otp}", email, otp);
    }

    public async Task SendPasswordResetEmailAsync(string email, string token)
    {
        var subject = "Password Reset Request";
        var plainTextContent = $"Your password reset token is: {token}. It will expire in 15 minutes.";
        var htmlContent = $"<strong>Your password reset token is: {token}</strong><br>It will expire in 15 minutes.";
        
        await SendEmailInternalAsync(email, subject, plainTextContent, htmlContent);
    }

    public async Task SendPasswordChangedNotificationEmailAsync(string email)
    {
        var subject = "Your Password Has Been Changed";
        var plainTextContent = "Your account password was recently changed. If you did not make this change, please contact support immediately.";
        var htmlContent = "<strong>Your account password was recently changed.</strong><br>If you did not make this change, please contact support immediately.";
        
        await SendEmailInternalAsync(email, subject, plainTextContent, htmlContent);
    }

    public async Task SendAccountSuspensionEmailAsync(string email, string reason, string supportEmail)
    {
        var subject = "Account Suspension Notice";
        var reasonText = string.IsNullOrWhiteSpace(reason) ? "No reason provided." : reason;
        var plainTextContent = $"Your account has been suspended or banned.\nReason: {reasonText}\n\nIf you believe this is an error, please contact us at {supportEmail}";
        var htmlContent = $"<strong>Your account has been suspended or banned.</strong><br>Reason: {reasonText}<br><br>If you believe this is an error, please contact us at <a href=\"mailto:{supportEmail}\">{supportEmail}</a>";
        
        await SendEmailInternalAsync(email, subject, plainTextContent, htmlContent);
    }

    private async Task SendEmailInternalAsync(string toEmail, string subject, string plainTextContent, string htmlContent)
    {
        var provider = _configuration["EmailSettings:Provider"];
        var fromEmail = _configuration["EmailSettings:FromEmail"];
        var fromName = _configuration["EmailSettings:FromName"];

        try
        {
            if (string.Equals(provider, "SendGrid", StringComparison.OrdinalIgnoreCase))
            {
                var apiKey = _configuration["EmailSettings:SendGridApiKey"];
                if (!string.IsNullOrEmpty(apiKey) && apiKey != "SG.YOUR_API_KEY")
                {
                    var client = new SendGridClient(apiKey);
                    var from = new EmailAddress(fromEmail, fromName);
                    var to = new EmailAddress(toEmail);
                    var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);
                    
                    var response = await client.SendEmailAsync(msg);
                    if (!response.IsSuccessStatusCode)
                    {
                        var body = await response.Body.ReadAsStringAsync();
                        _logger.LogError("Failed to send email via SendGrid to {Email}. Status: {Status}. Error: {Error}", toEmail, response.StatusCode, body);
                    }
                    return;
                }
            }

            // Fallback to SMTP
            var smtpHost = _configuration["EmailSettings:SmtpHost"];
            if (!string.IsNullOrEmpty(smtpHost))
            {
                var smtpPort = int.Parse(_configuration["EmailSettings:SmtpPort"] ?? "587");
                var smtpUser = _configuration["EmailSettings:SmtpUser"];
                var smtpPass = _configuration["EmailSettings:SmtpPass"];

                using var smtpClient = new SmtpClient(smtpHost, smtpPort)
                {
                    Credentials = new NetworkCredential(smtpUser, smtpPass),
                    EnableSsl = true
                };

                using var mailMessage = new MailMessage
                {
                    From = new MailAddress(fromEmail, fromName),
                    Subject = subject,
                    Body = htmlContent,
                    IsBodyHtml = true
                };
                mailMessage.To.Add(toEmail);

                await smtpClient.SendMailAsync(mailMessage);
                _logger.LogInformation("Sent email via SMTP to {Email}", toEmail);
                return;
            }

            _logger.LogWarning("No valid email provider configured. Email not sent to {Email}. Subject: {Subject}", toEmail, subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Exception while sending email to {Email}", toEmail);
        }
    }
}
