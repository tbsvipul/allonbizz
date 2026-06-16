using routent.AdminAPI.DTOs.Keepers;
using routent.AdminAPI.Models.Entities;

namespace routent.AdminAPI.Helpers;

public static class KeeperDocumentHelper
{
    public static List<KeeperDocumentDto> BuildDocuments(Keeper keeper)
    {
        if (keeper.Documents.Count > 0)
        {
            return keeper.Documents
                .OrderBy(document => document.CreatedAt)
                .Select(ToDto)
                .ToList();
        }

        if (string.IsNullOrWhiteSpace(keeper.DocumentData))
        {
            return new List<KeeperDocumentDto>();
        }

        return new List<KeeperDocumentDto>
        {
            new()
            {
                Id = keeper.KeeperId.ToString(),
                Name = "Business Document",
                Type = "Primary",
                Url = NormalizeDocumentReference(keeper.DocumentData),
                Status = "pending"
            }
        };
    }

    public static KeeperDocumentDto ToDto(KeeperDocument document)
    {
        return new KeeperDocumentDto
        {
            Id = document.DocumentId.ToString(),
            Name = document.Name,
            Type = document.DocumentType,
            Url = NormalizeDocumentReference(document.DocumentReference),
            Status = NormalizeDocumentStatus(document.Status),
            ReviewNotes = document.ReviewNotes,
            ReviewedAt = document.ReviewedAt
        };
    }

    public static string NormalizeDocumentReference(string? documentReference)
    {
        if (string.IsNullOrWhiteSpace(documentReference))
        {
            return string.Empty;
        }

        var trimmedReference = documentReference.Trim();
        return trimmedReference.StartsWith("http", StringComparison.OrdinalIgnoreCase) ||
               trimmedReference.StartsWith("data:", StringComparison.OrdinalIgnoreCase)
            ? trimmedReference
            : $"data:application/octet-stream;base64,{trimmedReference}";
    }

    public static string NormalizeDocumentStatus(string? status)
    {
        return string.IsNullOrWhiteSpace(status) ? "pending" : status.Trim().ToLowerInvariant();
    }
}
