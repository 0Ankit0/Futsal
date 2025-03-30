using System;
using FluentValidation;
using FutsalApi.ApiService.Data;

namespace FutsalApi.ApiService.Validators;

public class ReviewValidator : AbstractValidator<Review>
{
    public ReviewValidator()
    {
        RuleFor(x => x.UserId).NotEmpty().WithMessage("User ID is required");
        RuleFor(x => x.GroundId).NotEmpty().WithMessage("Ground ID is required");
        RuleFor(x => x.Rating).InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5");
    }
}

