//
//  DocumentSearch.swift
//  DocScan
//

import Foundation

enum DocumentSearch {
    static func matches(query: String, document: some SearchableDocument) -> Bool {
        matches(query: query, searchableText: document.searchableText)
    }

    static func matches(query: String, searchableText: String) -> Bool {
        let normalizedQuery = normalize(query).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else {
            return true
        }

        let normalizedText = normalize(searchableText)

        if normalizedText.contains(normalizedQuery) {
            return true
        }

        let queryTokens = tokens(in: normalizedQuery)
        guard !queryTokens.isEmpty else {
            return true
        }

        return queryTokens.allSatisfy { normalizedText.contains($0) }
    }

    static func snippet(for text: String, query: String, fallback: String) -> String {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            return fallback
        }

        let queryTokens = tokens(in: query)
        guard let firstToken = queryTokens.first else {
            return clipped(lines[0])
        }

        let matchingLine = lines.first { line in
            normalize(line).contains(firstToken)
        }

        return clipped(matchingLine ?? lines[0])
    }

    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static func tokens(in text: String) -> [String] {
        normalize(text)
            .split { character in
                character.isWhitespace || character.isPunctuation || character.isSymbol
            }
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private static func clipped(_ text: String, maxLength: Int = 160) -> String {
        guard text.count > maxLength else {
            return text
        }

        return String(text.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}

protocol SearchableDocument {
    var searchableText: String { get }
}
