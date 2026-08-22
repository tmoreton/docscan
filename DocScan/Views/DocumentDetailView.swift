//
//  DocumentDetailView.swift
//  DocScan
//

import SwiftData
import SwiftUI
import UIKit

struct DocumentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let document: ScannedDocument
    @State private var isDeleteConfirmationPresented = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                metadata
                pageImages
                recognizedText
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !document.recognizedText.isEmpty {
                    Button {
                        UIPasteboard.general.string = document.recognizedText
                    } label: {
                        Label("Copy Text", systemImage: "doc.on.doc")
                    }
                }

                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("Delete this document?", isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteDocument()
            }

            Button("Cancel", role: .cancel) {}
        }
        .alert("DocScan", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
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
            Text(document.category)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.accentColor.opacity(0.12), in: Capsule())

            HStack(spacing: 12) {
                Text(document.createdAt.formatted(date: .abbreviated, time: .shortened))
                Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
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

            Text(document.recognizedText.isEmpty ? "No text recognized." : document.recognizedText)
                .font(.body.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func deleteDocument() {
        do {
            modelContext.delete(document)
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
