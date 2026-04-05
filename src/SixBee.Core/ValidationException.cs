namespace SixBee.Core;

public class ValidationException : Exception
{
    public IReadOnlyList<ValidationError> Errors { get; }

    public ValidationException(IEnumerable<ValidationError> errors)
        : base("Validation failed")
    {
        Errors = errors.ToList().AsReadOnly();
    }
}

public record ValidationError(string Field, string Message);
