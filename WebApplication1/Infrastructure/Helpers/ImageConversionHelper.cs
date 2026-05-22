using System;

namespace allonbiz.AdminAPI.Helpers;

public static class ImageConversionHelper
{
    /// <summary>
    /// Parses a base64 string (optionally containing the "data:image/...;base64," prefix) into a byte array.
    /// </summary>
    public static byte[]? ParseBase64Image(string? base64Str)
    {
        if (string.IsNullOrWhiteSpace(base64Str)) return null;

        var cleanStr = base64Str.Trim();
        var commaIndex = cleanStr.IndexOf(',');
        if (commaIndex >= 0)
        {
            cleanStr = cleanStr.Substring(commaIndex + 1);
        }

        try
        {
            return Convert.FromBase64String(cleanStr);
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// Converts a binary byte array image into a standard base64 Data URL string.
    /// </summary>
    public static string? ToBase64DataUrl(byte[]? bytes, string defaultMediaType = "image/jpeg")
    {
        if (bytes == null || bytes.Length == 0) return null;

        var mediaType = defaultMediaType;
        if (bytes.Length >= 4)
        {
            if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47)
                mediaType = "image/png";
            else if (bytes[0] == 0xFF && bytes[1] == 0xD8)
                mediaType = "image/jpeg";
            else if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46)
                mediaType = "image/webp";
        }

        return $"data:{mediaType};base64,{Convert.ToBase64String(bytes)}";
    }
}
