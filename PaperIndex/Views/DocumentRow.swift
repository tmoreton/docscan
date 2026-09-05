//
//  DocumentRow.swift
//  PaperIndex
//

import SwiftUI

struct DocumentRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let document: ScannedDocument
    let searchText: String

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 14) {
                        thumbnail
                        documentInfo(titleLineLimit: 3)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        categoryBadge
                        fileStatus
                    }

                    if hasSearchQuery {
                        searchSnippet
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 14) {
                    thumbnail

                    VStack(alignment: .leading, spacing: 7) {
                        documentInfo(titleLineLimit: 1)

                        HStack(spacing: 8) {
                            categoryBadge
                            fileStatus
                        }

                        if hasSearchQuery {
                            searchSnippet
                        }
                    }
                    .padding(.top, 2)

                    Spacer(minLength: 8)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(PaperIndexStyle.surface)
                .shadow(color: PaperIndexStyle.shadow, radius: 12, x: 0, y: 6)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PaperIndexStyle.border, lineWidth: 1)
        }
    }

    private func documentInfo(titleLineLimit: Int) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(document.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PaperIndexStyle.ink)
                .lineLimit(titleLineLimit)

            Text(metadata)
                .font(.caption)
                .foregroundStyle(PaperIndexStyle.secondaryInk)
                .lineLimit(2)
        }
    }

    private var categoryBadge: some View {
        Text(document.category)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(PaperIndexStyle.secondaryInk)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minHeight: 24)
            .background(PaperIndexStyle.mutedSurface, in: Capsule())
    }

    private var fileStatus: some View {
        Group {
            if document.filesExportedAt == nil {
                Label("Preparing Files copy", systemImage: "clock")
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .accessibilityLabel("Saved in Files")
            }
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(document.filesExportedAt == nil ? PaperIndexStyle.tertiaryInk : PaperIndexStyle.blue)
    }

    private var searchSnippet: some View {
        Text(snippet)
            .font(.subheadline)
            .foregroundStyle(PaperIndexStyle.secondaryInk)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(PaperIndexStyle.mutedSurface)

            if let data = document.sortedPages.first?.imageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .saturation(0)
                    .contrast(1.18)
                    .brightness(0.03)
                    .frame(width: 60, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: "doc.viewfinder")
                    .font(.title2)
                    .foregroundStyle(PaperIndexStyle.secondaryInk)
            }
        }
        .frame(width: 60, height: 78)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PaperIndexStyle.border, lineWidth: 1)
        }
    }

    private var metadata: String {
        "\(document.createdAt.formatted(date: .abbreviated, time: .omitted))  ·  \(document.pageCount) page\(document.pageCount == 1 ? "" : "s")"
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
