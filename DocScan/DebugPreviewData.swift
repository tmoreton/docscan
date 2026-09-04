#if DEBUG

import SwiftData
import UIKit

@MainActor
enum DebugPreviewData {
    static func seedIfRequested(in context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-seed-preview-data"),
              let documentCount = try? context.fetchCount(FetchDescriptor<ScannedDocument>()),
              documentCount == 0 else {
            return
        }

        let samples = [
            Sample(
                title: "September utility statement",
                category: DocumentCategory.utilities,
                summary: "Monthly electricity statement with an upcoming payment date.",
                text: "North Harbor Energy\nStatement date: September 1, 2026\nAmount due: $84.17\nPayment due: September 18, 2026"
            ),
            Sample(
                title: "Harbor Dental receipt",
                category: DocumentCategory.receipts,
                summary: "Receipt for a routine dental visit.",
                text: "Harbor Dental\nRoutine examination\nTotal paid: $125.00\nThank you"
            ),
            Sample(
                title: "Home insurance renewal",
                category: DocumentCategory.insurance,
                summary: "Annual homeowners insurance renewal notice.",
                text: "Hearthline Insurance\nHome policy renewal\nCoverage period: 2026–2027\nPlease review your policy details."
            )
        ]

        for (offset, sample) in samples.enumerated() {
            let createdAt = Calendar.current.date(byAdding: .day, value: -offset * 8, to: Date()) ?? Date()
            let id = UUID()
            let imageData = samplePage(title: sample.title, body: sample.text).jpegData(compressionQuality: 0.9)
            let page = ScannedPage(index: 0, imageData: imageData, recognizedText: sample.text, createdAt: createdAt)
            let document = ScannedDocument(
                id: id,
                title: sample.title,
                category: sample.category.rawValue,
                fullText: sample.text,
                documentSummary: sample.summary,
                keywordsText: sample.category.rawValue,
                fileStorageFolderName: DocumentFileStore.makeFolderName(title: sample.title, createdAt: createdAt, id: id),
                createdAt: createdAt,
                updatedAt: createdAt,
                pageCount: 1,
                pages: [page]
            )
            page.document = document
            context.insert(document)

            if let report = try? DocumentFileStore.export(DocumentFileStore.exportPackage(for: document)) {
                document.filesExportedAt = report.exportedAt
            }
        }

        try? context.save()
    }

    private static func samplePage(title: String, body: String) -> UIImage {
        let size = CGSize(width: 900, height: 1_200)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 44, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 27, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            NSString(string: title).draw(
                in: CGRect(x: 74, y: 80, width: 752, height: 130),
                withAttributes: titleAttributes
            )
            NSString(string: body).draw(
                in: CGRect(x: 74, y: 250, width: 752, height: 760),
                withAttributes: bodyAttributes
            )
        }
    }

    private struct Sample {
        let title: String
        let category: DocumentCategory
        let summary: String
        let text: String
    }
}

#endif
