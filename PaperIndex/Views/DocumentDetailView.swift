//
//  DocumentDetailView.swift
//  PaperIndex
//

import SwiftData
import SwiftUI
import UIKit

struct DocumentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                filesButton
                pageImages
                recognizedText
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(PaperIndexStyle.background)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(PaperIndexStyle.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DetailMoreMenu(
                    isOpeningFiles: isExportingFiles,
                    hasRecognizedText: !displayRecognizedText.isEmpty,
                    openFilesAction: openFiles,
                    copyTextAction: copyRecognizedText,
                    deleteAction: { isDeleteConfirmationPresented = true }
                )
            }
        }
        .overlay(alignment: .top) {
            if hasCopiedText {
                Label("Recognized text copied", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .background(PaperIndexStyle.darkSurface, in: Capsule())
                    .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 8)
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
        .confirmationDialog("Delete from PaperIndex?", isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteDocument()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Exported copies in Files are left in place.")
        }
        .alert("PaperIndex", isPresented: errorAlertBinding) {
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
            sectionHeader(
                title: "Scanned pages",
                detail: "\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")"
            )

            ForEach(document.sortedPages) { page in
                if let data = page.imageData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .saturation(0)
                        .contrast(1.2)
                        .brightness(0.03)
                        .padding(8)
                        .background(PaperIndexStyle.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PaperIndexStyle.border, lineWidth: 1)
                        }
                        .shadow(color: PaperIndexStyle.shadow, radius: 12, x: 0, y: 6)
                }
            }
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        categoryBadge
                        createdDate
                    }
                } else {
                    HStack(spacing: 10) {
                        categoryBadge
                        createdDate
                        Spacer(minLength: 0)
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !document.cleanedSummary.isEmpty {
                Text(document.cleanedSummary)
                    .font(.body)
                    .foregroundStyle(PaperIndexStyle.ink)
                    .lineSpacing(3)
                    .textSelection(.enabled)
            }
        }
    }

    private var categoryBadge: some View {
        Text(document.category)
            .font(.caption.weight(.semibold))
            .foregroundStyle(PaperIndexStyle.secondaryInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(PaperIndexStyle.mutedSurface, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(PaperIndexStyle.border, lineWidth: 1)
            }
    }

    private var createdDate: some View {
        Text(document.createdAt.formatted(date: .abbreviated, time: .shortened))
            .foregroundStyle(PaperIndexStyle.secondaryInk)
    }

    private var filesButton: some View {
        Button(action: openFiles) {
            HStack(spacing: 8) {
                if isExportingFiles {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "folder")
                }

                Text("View in Files")
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(PaperIndexStyle.blue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isExportingFiles)
    }

    private func sectionHeader(title: String, detail: String) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 3) {
                    sectionTitle(title)
                    sectionDetail(detail)
                }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    sectionTitle(title)
                    Spacer(minLength: 8)
                    sectionDetail(detail)
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(PaperIndexStyle.ink)
    }

    private func sectionDetail(_ detail: String) -> some View {
        Text(detail)
            .font(.caption.weight(.medium))
            .foregroundStyle(PaperIndexStyle.tertiaryInk)
    }

    private var recognizedText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader(title: "Recognized text", detail: "Searchable")
                        copyTextButton
                    }
                } else {
                    HStack(spacing: 12) {
                        sectionHeader(title: "Recognized text", detail: "Searchable")
                        Spacer(minLength: 8)
                        copyTextButton
                    }
                }
            }

            Text(displayRecognizedText.isEmpty ? "No text recognized." : displayRecognizedText)
                .font(.body)
                .lineSpacing(6)
                .foregroundStyle(PaperIndexStyle.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
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
    }

    private var copyTextButton: some View {
        Button(action: copyRecognizedText) {
            Label(
                hasCopiedText ? "Copied" : "Copy text",
                systemImage: hasCopiedText ? "checkmark" : "doc.on.doc"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(displayRecognizedText.isEmpty ? PaperIndexStyle.tertiaryInk : PaperIndexStyle.blue)
            .padding(.horizontal, 13)
            .frame(minHeight: 42)
            .background(PaperIndexStyle.surface, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(PaperIndexStyle.border, lineWidth: 1)
            }
            .shadow(color: PaperIndexStyle.shadow.opacity(0.45), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(displayRecognizedText.isEmpty)
        .accessibilityLabel(hasCopiedText ? "Recognized text copied" : "Copy recognized text")
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
            errorMessage = "PaperIndex could not write the Files copies: \(error.localizedDescription)"
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
            errorMessage = "PaperIndex could not find the exported Files folder."
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

private struct DetailMoreMenu: View {
    let isOpeningFiles: Bool
    let hasRecognizedText: Bool
    let openFilesAction: () -> Void
    let copyTextAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        Menu {
            Button(action: openFilesAction) {
                Label("View in Files", systemImage: "folder")
            }
            .disabled(isOpeningFiles)

            Button(action: copyTextAction) {
                Label("Copy recognized text", systemImage: "doc.on.doc")
            }
            .disabled(!hasRecognizedText)

            Divider()

            Button(role: .destructive, action: deleteAction) {
                Label("Delete document", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(PaperIndexStyle.ink)
                .frame(width: 42, height: 42)
        }
        .accessibilityLabel("Document actions")
    }
}
