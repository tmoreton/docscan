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
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.white)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !document.cleanedRecognizedText.isEmpty {
                    Button {
                        UIPasteboard.general.string = document.cleanedRecognizedText
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
                        .saturation(0)
                        .contrast(1.2)
                        .brightness(0.03)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
                        }
                }
            }
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(document.category)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())

                Text(document.createdAt.formatted(date: .abbreviated, time: .shortened))
                Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                Spacer(minLength: 0)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            if !document.cleanedSummary.isEmpty {
                Text(document.cleanedSummary)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .textSelection(.enabled)
            }
        }
    }

    private var recognizedText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Recognized Text")
                .font(.headline)

            Text(document.cleanedRecognizedText.isEmpty ? "No text recognized." : document.cleanedRecognizedText)
                .font(.body)
                .lineSpacing(5)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
