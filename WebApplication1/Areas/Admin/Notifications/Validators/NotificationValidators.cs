using FluentValidation;
using allonbiz.AdminAPI.DTOs.Admin;

namespace allonbiz.AdminAPI.Validators;

public class CreateNotificationDtoValidator : AbstractValidator<CreateNotificationDto>
{
    public CreateNotificationDtoValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Title is required.")
            .MaximumLength(200).WithMessage("Title cannot exceed 200 characters.");

        RuleFor(x => x.Message)
            .NotEmpty().WithMessage("Message is required.")
            .MaximumLength(2000).WithMessage("Message cannot exceed 2000 characters.");

        RuleFor(x => x.Type)
            .NotEmpty().WithMessage("Notification type is required.");

        RuleFor(x => x.Priority)
            .NotEmpty().WithMessage("Priority is required.");

        RuleFor(x => x.TargetAudience)
            .NotEmpty().WithMessage("Target audience is required.");

        RuleFor(x => x.ScheduledAt)
            .Must(date => !date.HasValue || date.Value > DateTime.UtcNow)
            .WithMessage("Scheduled time must be in the future.");
            
        RuleFor(x => x.ExpiresAt)
            .Must((dto, date) => !date.HasValue || !dto.ScheduledAt.HasValue || date.Value > dto.ScheduledAt.Value)
            .WithMessage("Expiration time must be after the scheduled time.");
    }
}
