//
//  DocumentRow.swift
//  DocScan
//

import SwiftUI

struct DocumentRow: View {
    let document: ScannedDocument
    let searchText: String

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(document.category)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                        .lineLimit(1)
                }

                Text(snippet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Text(document.createdAt, style: .date)
                    Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.quaternary)

            if let data = document.sortedPages.first?.imageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 74)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Image(systemName: "doc.viewfinder")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 58, height: 74)
    }

    private var snippet: String {
        DocumentSearch.snippet(
            for: document.recognizedText,
            query: searchText,
            fallback: document.previewText
        )
    }
}
