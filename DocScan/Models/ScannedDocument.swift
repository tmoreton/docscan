//
//  ScannedDocument.swift
//  DocScan
//

import Foundation
import SwiftData

@Model
final class ScannedDocument {
    var id: UUID = UUID()
    @Attribute(.spotlight, .allowsCloudEncryption) var title: String = ""
    @Attribute(.spotlight, .allowsCloudEncryption) var category: String = DocumentCategory.general.rawValue
    @Attribute(.spotlight, .allowsCloudEncryption) var fullText: String = ""
    @Attribute(.spotlight, .allowsCloudEncryption) var documentSummary: String = ""
    @Attribute(.spotlight, .allowsCloudEncryption) var keywordsText: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var pageCount: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \ScannedPage.document)
    var pages: [ScannedPage]? = []

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        fullText: String,
        documentSummary: String = "",
        keywordsText: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        pageCount: Int = 0,
        pages: [ScannedPage] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.fullText = fullText
        self.documentSummary = documentSummary
        self.keywordsText = keywordsText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pageCount = pageCount
        self.pages = pages
    }

    var sortedPages: [ScannedPage] {
        (pages ?? []).sorted { $0.index < $1.index }
    }

    var recognizedText: String {
        if !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fullText
        }

        return sortedPages
            .map(\.recognizedText)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")
    }

    var searchableText: String {
        ([title, category, documentSummary, keywordsText, recognizedText] + sortedPages.map(\.recognizedText))
            .joined(separator: " ")
    }

    var cleanedSummary: String {
        documentSummary
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    var cleanedRecognizedText: String {
        recognizedText
            .split(whereSeparator: \.isNewline)
            .map { line in
                line
                    .split(whereSeparator: \.isWhitespace)
                    .joined(separator: " ")
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    var snippetText: String {
        [cleanedSummary, cleanedRecognizedText, keywordsText]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
    }

    var previewText: String {
        cleanedRecognizedText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? (cleanedSummary.isEmpty ? "No text recognized" : cleanedSummary)
    }
}

extension ScannedDocument: SearchableDocument {
}

@Model
final class ScannedPage {
    var id: UUID = UUID()
    var index: Int = 0
    @Attribute(.externalStorage, .allowsCloudEncryption) var imageData: Data?
    @Attribute(.spotlight, .allowsCloudEncryption) var recognizedText: String = ""
    var createdAt: Date = Date()
    var document: ScannedDocument?

    init(
        id: UUID = UUID(),
        index: Int,
        imageData: Data?,
        recognizedText: String,
        createdAt: Date = Date(),
        document: ScannedDocument? = nil
    ) {
        self.id = id
        self.index = index
        self.imageData = imageData
        self.recognizedText = recognizedText
        self.createdAt = createdAt
        self.document = document
    }
}
