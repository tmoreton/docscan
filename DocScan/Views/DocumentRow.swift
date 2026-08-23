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

            VStack(alignment: .leading, spacing: 5) {
                Text(document.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(metadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if hasSearchQuery {
                    Text(snippet)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 8)
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: 0.95, green: 0.95, blue: 0.94))

            if let data = document.sortedPages.first?.imageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .saturation(0)
                    .contrast(1.18)
                    .brightness(0.03)
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

    private var metadata: String {
        "\(document.createdAt.formatted(date: .abbreviated, time: .omitted)) - \(document.pageCount) page\(document.pageCount == 1 ? "" : "s") - \(document.category)"
    }

    private var hasSearchQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var snippet: String {
        DocumentSearch.snippet(
            for: document.snippetText,
            query: searchText,
            fallback: document.previewText
        )
    }
}
