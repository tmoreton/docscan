//
//  DocumentDetailView.swift
//  DocScan
//

import SwiftData
import SwiftUI

struct DocumentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let document: ScannedDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageImages
                metadata
                recognizedText
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    deleteDocument()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var pageImages: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(document.sortedPages) { page in
                if let data = page.imageData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.quaternary, lineWidth: 1)
                        }
                }
            }
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(document.category, systemImage: DocumentCategory(rawValue: document.category)?.iconName ?? "folder")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 12) {
                Label(document.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                Label("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")", systemImage: "doc.on.doc")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var recognizedText: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recognized Text")
                .font(.headline)

            Text(document.fullText.isEmpty ? "No text recognized." : document.fullText)
                .font(.body.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func deleteDocument() {
        modelContext.delete(document)
        try? modelContext.save()
        dismiss()
    }
}
