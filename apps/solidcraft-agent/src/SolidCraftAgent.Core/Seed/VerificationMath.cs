namespace SolidCraftAgent.Core.Seed;

/// <summary>
/// Deterministic verification helpers seeded from modelling history corrections.
/// </summary>
public static class VerificationMath
{
    /// <summary>
    /// Bevel callout W × A° on plate thickness T.
    /// Width = W; depth = W * tan(A); flat = T - depth.
    /// </summary>
    public static BevelGeometry ComputeBevel(double width, double angleDegrees, double thickness)
    {
        if (width <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(width));
        }

        if (angleDegrees is <= 0 or >= 90)
        {
            throw new ArgumentOutOfRangeException(nameof(angleDegrees));
        }

        if (thickness <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(thickness));
        }

        var radians = angleDegrees * Math.PI / 180.0;
        var depth = width * Math.Tan(radians);
        var flat = thickness - depth;
        var rejectedFullThicknessWidth = thickness / Math.Tan(radians);
        return new BevelGeometry(width, angleDegrees, thickness, depth, flat, rejectedFullThicknessWidth);
    }

    public static bool IsFullThicknessCutMistakenForWidth(double measuredWidth, double thickness, double angleDegrees, double tolerance = 0.02)
    {
        var expectedMistake = thickness / Math.Tan(angleDegrees * Math.PI / 180.0);
        return Math.Abs(measuredWidth - expectedMistake) <= tolerance;
    }
}

public readonly record struct BevelGeometry(
    double Width,
    double AngleDegrees,
    double Thickness,
    double Depth,
    double Flat,
    double RejectedFullThicknessWidth);
