using System;

using FluentValidation;

using FutsalApi.Data.Models;

namespace FutsalApi.ApiService.Validators;

public class BookingRequestValidator : AbstractValidator<BookingRequest>
{
    public BookingRequestValidator()
    {
        RuleFor(x => x.GroundId).NotEmpty().WithMessage("Ground ID is required");
        RuleFor(x => x.BookingDate).GreaterThanOrEqualTo(DateTime.UtcNow.Date)
            .WithMessage("Booking date cannot be in the past");
        RuleFor(x => x.StartTime).LessThan(x => x.EndTime)
            .WithMessage("Start time must be before end time");
    }
}
