//
//  DocumentFileStore.swift
//  DocScan
//

import Foundation

struct DocumentFileExportPackage: Sendable {
    let id: UUID
    let title: String
    let category: String
    let createdAt: Date
    let pageCount: Int
    let folderName: String
    let recognizedText: String
    let pages: [DocumentFileExportPage]
}

struct DocumentFileExportPage: Sendable {
    let index: Int
    let imageData: Data
}

struct DocumentFileExportReport: Sendable {
    let exportedAt: Date
    let locations: [DocumentFileLocation]
}

struct DocumentFileLocation: Identifiable, Equatable, Sendable {
    enum Kind: String, Sendable {
        case local
        case iCloud
    }

    let kind: Kind
    let url: URL
    let displayPath: String
    let persistenceNote: String

    var id: String {
        kind.rawValue
    }

    var title: String {
        switch kind {
        case .local:
            "On My iPhone"
        case .iCloud:
            "iCloud Drive"
        }
    }

    var systemImage: String {
        switch kind {
        case .local:
            "iphone"
        case .iCloud:
            "icloud"
        }
    }
}

struct DocumentFileLocations: Sendable {
    let local: DocumentFileLocation
    let iCloud: DocumentFileLocation?

    var available: [DocumentFileLocation] {
        [local] + [iCloud].compactMap { $0 }
    }
}

enum DocumentFileStore {
    static let archiveFolderName = "DocScan Archive"
    static let iCloudContainerIdentifier = "iCloud.reactnativenerd.DocScan"

    static func ensureFolderName(for document: ScannedDocument) -> String {
        if document.fileStorageFolderName.isEmpty {
            document.fileStorageFolderName = makeFolderName(
                title: document.title,
                createdAt: document.createdAt,
                id: document.id
            )
        }

        return document.fileStorageFolderName
    }

    static func exportPackage(for document: ScannedDocument) -> DocumentFileExportPackage {
        let folderName = ensureFolderName(for: document)
        let pages = document.sortedPages.compactMap { page -> DocumentFileExportPage? in
            guard let imageData = page.imageData else {
                return nil
            }

            return DocumentFileExportPage(index: page.index, imageData: imageData)
        }

        return DocumentFileExportPackage(
            id: document.id,
            title: document.title,
            category: document.category,
            createdAt: document.createdAt,
            pageCount: document.pageCount,
            folderName: folderName,
            recognizedText: document.formattedRecognizedText,
            pages: pages
        )
    }

    static func export(_ package: DocumentFileExportPackage) throws -> DocumentFileExportReport {
        let locations = availableLocations(folderName: package.folderName)

        for location in locations.available {
            try write(package, to: location.url)
        }

        return DocumentFileExportReport(exportedAt: Date(), locations: locations.available)
    }

    static func availableLocations(folderName: String) -> DocumentFileLocations {
        let local = DocumentFileLocation(
            kind: .local,
            url: localArchiveURL.appendingPathComponent(folderName, isDirectory: true),
            displayPath: "Files > On My iPhone > DocScan > \(archiveFolderName) > \(folderName)",
            persistenceNote: "Visible while the app is installed. iOS removes this copy if the app is deleted."
        )

        let iCloud = iCloudArchiveURL.map { rootURL in
            DocumentFileLocation(
                kind: .iCloud,
                url: rootURL.appendingPathComponent(folderName, isDirectory: true),
                displayPath: "Files > iCloud Drive > DocScan > \(archiveFolderName) > \(folderName)",
                persistenceNote: "This is the durable Files copy when iCloud Drive is enabled."
            )
        }

        return DocumentFileLocations(local: local, iCloud: iCloud)
    }

    static func makeFolderName(title: String, createdAt: Date, id: UUID) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"

        let datePart = dateFormatter.string(from: createdAt)
        let titlePart = sanitizedPathComponent(title, fallback: "Document", maxLength: 46)
        let idPart = id.uuidString.prefix(8)
        return "\(datePart)-\(titlePart)-\(idPart)"
    }

    private static var localArchiveURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(archiveFolderName, isDirectory: true)
    }

    private static var iCloudArchiveURL: URL? {
        FileManager.default
            .url(forUbiquityContainerIdentifier: iCloudContainerIdentifier)?
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent(archiveFolderName, isDirectory: true)
    }

    private static func write(_ package: DocumentFileExportPackage, to folderURL: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)

        try overviewText(for: package)
            .write(
                to: folderURL.appendingPathComponent("Document Info.txt"),
                atomically: true,
                encoding: .utf8
            )

        try ocrText(for: package)
            .write(
                to: folderURL.appendingPathComponent("OCR Text.txt"),
                atomically: true,
                encoding: .utf8
            )

        for page in package.pages {
            let fileName = "Page \(String(format: "%02d", page.index + 1)).jpg"
            try page.imageData.write(to: folderURL.appendingPathComponent(fileName), options: .atomic)
        }
    }

    private static func overviewText(for package: DocumentFileExportPackage) -> String {
        """
        Title: \(package.title)
        Category: \(package.category)
        Scanned: \(package.createdAt.formatted(date: .abbreviated, time: .shortened))
        Pages: \(package.pageCount)
        Document ID: \(package.id.uuidString)

        This folder contains the exported scan image files and the recognized OCR text.
        The app's internal SwiftData and CloudKit record is separate from these user-visible files.
        """
    }

    private static func ocrText(for package: DocumentFileExportPackage) -> String {
        if package.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No text recognized."
        }

        return package.recognizedText
    }

    private static func sanitizedPathComponent(_ value: String, fallback: String, maxLength: Int) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_"))
        let cleaned = String(
            value.unicodeScalars.map { scalar in
                allowed.contains(scalar) ? Character(scalar) : "-"
            }
        )
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: "-")
        .split(separator: "-")
        .filter { !$0.isEmpty }
        .joined(separator: "-")

        let limited = String(cleaned.prefix(maxLength)).trimmingCharacters(in: CharacterSet(charactersIn: "-_ "))
        return limited.isEmpty ? fallback : limited
    }
}
