namespace routent.AdminAPI.Models.Entities;

public class AuthChallenge
{
    public Guid ChallengeId { get; set; } = Guid.NewGuid();
    public string AccountType { get; set; } = string.Empty; // admin | user
    public Guid? AccountId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string ChallengeType { get; set; } = string.Empty; // otp | password_reset
    public string SecretHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime? ConsumedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
