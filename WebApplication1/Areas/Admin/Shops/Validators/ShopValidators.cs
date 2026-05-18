using FluentValidation;
using allonbiz.AdminAPI.DTOs.Shops;

namespace allonbiz.AdminAPI.Validators;

public class UpdateShopStatusDtoValidator : AbstractValidator<UpdateShopStatusDto>
{
    public UpdateShopStatusDtoValidator()
    {
        RuleFor(x => x.IsActive)
            .NotNull().WithMessage("Status (IsActive) is required.");

        RuleFor(x => x.Reason)
            .NotEmpty()
            .When(x => !x.IsActive)
            .WithMessage("A reason is required when deactivating a shop.")
            .MaximumLength(500).WithMessage("Reason cannot exceed 500 characters.");
    }
}

public class CreateShopRequestDtoValidator : AbstractValidator<CreateShopRequestDto>
{
    public CreateShopRequestDtoValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Shop name is required.")
            .MaximumLength(200).WithMessage("Shop name cannot exceed 200 characters.");

        RuleFor(x => x.KeeperId)
            .NotEmpty().WithMessage("Keeper ID is required.");

        RuleFor(x => x.Email)
            .EmailAddress().When(x => !string.IsNullOrEmpty(x.Email))
            .WithMessage("Invalid email format.");

        RuleFor(x => x.PhoneNumber)
            .MaximumLength(20).WithMessage("Phone number too long.");
            
        RuleFor(x => x.Latitude)
            .InclusiveBetween(-90, 90).When(x => x.Latitude.HasValue);
            
        RuleFor(x => x.Longitude)
            .InclusiveBetween(-180, 180).When(x => x.Longitude.HasValue);
    }
}
