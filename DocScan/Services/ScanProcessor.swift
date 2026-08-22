//
//  ScanProcessor.swift
//  DocScan
//

import UIKit

struct ProcessedScanPage {
    let index: Int
    let imageData: Data
    let recognizedText: String
}

enum ScanProcessor {
    enum ScanProcessorError: LocalizedError {
        case emptyScan
        case imageEncodingFailed

        var errorDescription: String? {
            switch self {
            case .emptyScan:
                "No pages were found in the scan."
            case .imageEncodingFailed:
                "The scanned image could not be saved."
            }
        }
    }

    static func process(images: [UIImage]) async throws -> [ProcessedScanPage] {
        guard !images.isEmpty else {
            throw ScanProcessorError.emptyScan
        }

        var pages: [ProcessedScanPage] = []
        pages.reserveCapacity(images.count)

        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.92) else {
                throw ScanProcessorError.imageEncodingFailed
            }

            let recognizedText = try await OCRService.recognizeText(in: image)
            pages.append(ProcessedScanPage(index: index, imageData: imageData, recognizedText: recognizedText))
        }

        return pages
    }
}
