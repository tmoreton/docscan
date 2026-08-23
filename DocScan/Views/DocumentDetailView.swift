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
    @State private var hasCopiedText = false
    @State private var copyFeedbackTask: Task<Void, Never>?
    @State private var storageLocations: DocumentFileLocations?
    @State private var storageBrowserLocation: DocumentFileLocation?
    @State private var isExportingFiles = false
    @State private var errorMessage: String?

    private var displayRecognizedText: String {
        document.formattedRecognizedText
    }

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
        .background(DocScanStyle.background)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DocScanStyle.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DetailActionPill(
                    isOpeningFiles: isExportingFiles,
                    openFilesAction: openFiles,
                    deleteAction: { isDeleteConfirmationPresented = true }
                )
            }
        }
        .overlay(alignment: .top) {
            if hasCopiedText {
                Text("Recognized text copied")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DocScanStyle.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .background(DocScanStyle.surface, in: Capsule())
                    .shadow(color: DocScanStyle.shadow, radius: 16, x: 0, y: 8)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onDisappear {
            copyFeedbackTask?.cancel()
        }
        .sheet(item: $storageBrowserLocation) { location in
            DocumentStorageBrowserView(directoryURL: location.url)
        }
        .task {
            exportFilesIfNeeded()
        }
        .confirmationDialog("Delete from DocScan?", isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteDocument()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Exported copies in Files are left in place.")
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
                        .background(DocScanStyle.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(DocScanStyle.border, lineWidth: 1)
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
                    .foregroundStyle(DocScanStyle.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DocScanStyle.blue.opacity(0.12), in: Capsule())

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
                    .foregroundStyle(DocScanStyle.ink)
                    .lineSpacing(3)
                    .textSelection(.enabled)
            }
        }
    }

    private var recognizedText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                Text("Recognized Text")
                    .font(.headline)
                    .foregroundStyle(DocScanStyle.ink)

                Spacer(minLength: 8)

                Button(action: copyRecognizedText) {
                    Image(systemName: hasCopiedText ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(displayRecognizedText.isEmpty ? DocScanStyle.secondaryInk.opacity(0.45) : DocScanStyle.ink)
                        .frame(width: 42, height: 36)
                        .background(DocScanStyle.surface, in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(DocScanStyle.border, lineWidth: 1)
                        }
                        .shadow(color: DocScanStyle.shadow.opacity(0.45), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(displayRecognizedText.isEmpty)
                .accessibilityLabel(hasCopiedText ? "Recognized text copied" : "Copy recognized text")
            }

            Text(displayRecognizedText.isEmpty ? "No text recognized." : displayRecognizedText)
                .font(.body)
                .lineSpacing(6)
                .foregroundStyle(DocScanStyle.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DocScanStyle.surface)
                        .shadow(color: DocScanStyle.shadow.opacity(0.55), radius: 12, x: 0, y: 6)
                )
        }
    }

    private func exportFilesIfNeeded() {
        refreshStorageLocations()

        guard document.filesExportedAt == nil else {
            return
        }

        exportFiles()
    }

    private func refreshStorageLocations() {
        let folderName = document.fileStorageFolderName.isEmpty
            ? DocumentFileStore.ensureFolderName(for: document)
            : document.fileStorageFolderName

        storageLocations = DocumentFileStore.availableLocations(folderName: folderName)
    }

    private func exportFiles() {
        guard !isExportingFiles else {
            return
        }

        isExportingFiles = true
        defer {
            isExportingFiles = false
        }

        do {
            let package = DocumentFileStore.exportPackage(for: document)
            let report = try DocumentFileStore.export(package)
            document.filesExportedAt = report.exportedAt
            try modelContext.save()
            storageLocations = DocumentFileStore.availableLocations(folderName: package.folderName)
        } catch {
            modelContext.rollback()
            refreshStorageLocations()
            errorMessage = "DocScan could not write the Files copies: \(error.localizedDescription)"
        }
    }

    private func openFiles() {
        guard !isExportingFiles else {
            return
        }

        if storageLocations == nil {
            refreshStorageLocations()
        }

        if document.filesExportedAt == nil {
            exportFiles()
            guard document.filesExportedAt != nil else {
                return
            }
        }

        guard let location = storageLocations?.iCloud ?? storageLocations?.local else {
            errorMessage = "DocScan could not find the exported Files folder."
            return
        }

        storageBrowserLocation = location
    }

    private func copyRecognizedText() {
        guard !displayRecognizedText.isEmpty else {
            return
        }

        UIPasteboard.general.string = displayRecognizedText

        copyFeedbackTask?.cancel()
        withAnimation(.easeOut(duration: 0.16)) {
            hasCopiedText = true
        }

        copyFeedbackTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            guard !Task.isCancelled else {
                return
            }

            withAnimation(.easeIn(duration: 0.16)) {
                hasCopiedText = false
            }
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

private struct DetailActionPill: View {
    let isOpeningFiles: Bool
    let openFilesAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: openFilesAction) {
                Image(systemName: "folder")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(isOpeningFiles ? DocScanStyle.secondaryInk.opacity(0.45) : DocScanStyle.ink)
                    .frame(width: 50, height: 46)
            }
            .buttonStyle(.plain)
            .disabled(isOpeningFiles)
            .accessibilityLabel("Open exported files")

            Rectangle()
                .fill(DocScanStyle.border)
                .frame(width: 1, height: 26)

            Button(action: deleteAction) {
                Image(systemName: "trash")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(DocScanStyle.ink)
                    .frame(width: 50, height: 46)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete document")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(DocScanStyle.surface)
                .shadow(color: DocScanStyle.shadow, radius: 18, x: 0, y: 10)
        )
    }
}
