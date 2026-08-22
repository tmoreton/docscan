//
//  DocumentMetadataService.swift
//  DocScan
//

import Foundation
import FoundationModels

struct DocumentMetadata: Sendable {
    let title: String
    let category: DocumentCategory
    let summary: String
    let keywords: [String]
    let source: DocumentMetadataSource
}

@Generable(description: "Searchable document metadata extracted from OCR text")
private struct GeneratedDocumentMetadata {
    @Guide(description: "A concise title based only on OCR text. Use 3 to 8 words.")
    var title: String

    @Guide(
        description: "The best category for the document.",
        .anyOf([
            "Receipts",
            "Invoices",
            "Tax",
            "Banking",
            "Medical",
            "Insurance",
            "Legal",
            "Travel",
            "Utilities",
            "Education",
            "Identity",
            "General"
        ])
    )
    var category: String

    @Guide(description: "One short sentence describing what the document is. Use an empty string if uncertain.")
    var summary: String

    @Guide(description: "Up to six short searchable keywords from the OCR text.", .maximumCount(6))
    var keywords: [String]
}

enum DocumentMetadataService {
    static func ruleBasedMetadata(for text: String, createdAt: Date) -> DocumentMetadata {
        let category = DocumentCategorizer.inferCategory(from: text)
        let title = DocumentCategorizer.makeTitle(from: text, createdAt: createdAt)

        return DocumentMetadata(
            title: title,
            category: category,
            summary: "",
            keywords: [],
            source: .rules
        )
    }

    static func enrichedMetadata(for text: String, createdAt: Date) async -> DocumentMetadata {
        let fallback = ruleBasedMetadata(for: text, createdAt: createdAt)
        let context = contextText(from: text)

        guard !context.isEmpty else {
            return fallback
        }

        let model = SystemLanguageModel(useCase: .contentTagging)
        guard case .available = model.availability,
              model.supportsLocale() else {
            return fallback
        }

        do {
            let session = LanguageModelSession(model: model, instructions: instructions)
            let response = try await session.respond(
                to: prompt(with: context),
                generating: GeneratedDocumentMetadata.self,
                options: GenerationOptions(sampling: .greedy, temperature: 0.0, maximumResponseTokens: 320)
            )

            return cleanedMetadata(from: response.content, fallback: fallback)
        } catch {
            return fallback
        }
    }

    private static let instructions = """
    You extract private document metadata from OCR text on device.
    Use only information visible in the OCR text. Do not guess missing facts.
    Choose exactly one supported category. Use General when uncertain.
    Keep titles, descriptions, and keywords concise.
    Do not include full account numbers, Social Security numbers, or other full identity numbers in titles, descriptions, or keywords.
    """

    private static func prompt(with text: String) -> String {
        """
        Create metadata for this scanned document.

        OCR text:
        \(text)
        """
    }

    private static func cleanedMetadata(
        from generated: GeneratedDocumentMetadata,
        fallback: DocumentMetadata
    ) -> DocumentMetadata {
        let title = cleanedText(generated.title, maxLength: 72)
        let summary = cleanedText(generated.summary, maxLength: 180)
        let category = DocumentCategory(rawValue: generated.category) ?? fallback.category
        let keywords = cleanedKeywords(generated.keywords)

        return DocumentMetadata(
            title: title.isEmpty ? fallback.title : title,
            category: category,
            summary: summary,
            keywords: keywords,
            source: .appleIntelligence
        )
    }

    private static func contextText(from text: String, maxCharacters: Int = 9_000) -> String {
        let cleaned = text
            .split(whereSeparator: \.isNewline)
            .map { line in
                line
                    .split(whereSeparator: \.isWhitespace)
                    .joined(separator: " ")
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        guard cleaned.count > maxCharacters else {
            return cleaned
        }

        let headCount = maxCharacters * 2 / 3
        let tailCount = maxCharacters - headCount
        return "\(cleaned.prefix(headCount))\n...\n\(cleaned.suffix(tailCount))"
    }

    private static func cleanedText(_ text: String, maxLength: Int) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))

        guard cleaned.count > maxLength else {
            return cleaned
        }

        return String(cleaned.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanedKeywords(_ keywords: [String]) -> [String] {
        var seen: Set<String> = []

        return keywords.compactMap { keyword in
            let cleaned = cleanedText(keyword, maxLength: 32)
            let normalized = DocumentSearch.normalize(cleaned)

            guard !cleaned.isEmpty,
                  cleaned.count >= 2,
                  !seen.contains(normalized) else {
                return nil
            }

            seen.insert(normalized)
            return cleaned
        }
    }
}

extension ScannedDocument {
    func applyMetadata(_ metadata: DocumentMetadata, updatedAt: Date = Date()) {
        title = metadata.title
        category = metadata.category.rawValue
        documentSummary = metadata.summary
        keywordsText = metadata.keywords.joined(separator: "\n")
        metadataSource = metadata.source.rawValue
        metadataUpdatedAt = updatedAt
        self.updatedAt = updatedAt
    }
}
