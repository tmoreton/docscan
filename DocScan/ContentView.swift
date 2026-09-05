//
//  ContentView.swift
//  DocScan
//
//  Created by Homelab on 8/21/26.
//

import SwiftData
import SwiftUI
import UIKit
import VisionKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScannedDocument.createdAt, order: .reverse) private var documents: [ScannedDocument]

    @AppStorage("hasPresentedInitialScanner") private var hasPresentedInitialScanner = false
    @State private var searchText = ""
    @State private var selectedCategory: DocumentCategory = .all
    @State private var navigationPath: [UUID] = []
    @State private var isScannerPresented = false
    @State private var isProcessingScan = false
    @State private var processingPageCount = 0
    @State private var savedNotice: SavedDocumentNotice?
    @State private var errorMessage: String?

    private var filteredDocuments: [ScannedDocument] {
        documents.filter { document in
            let matchesCategory = selectedCategory == .all || document.category == selectedCategory.rawValue
            return matchesCategory && DocumentSearch.matches(query: searchText, document: document)
        }
    }

    private var hasActiveFilter: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCategory != .all
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                DocumentArchiveHeader(
                    documentCount: documents.count,
                    onScan: presentScanner
                )

                if let savedNotice {
                    DocumentSavedNotice(
                        title: savedNotice.title,
                        storageSummary: savedNotice.storageSummary,
                        dismissAction: { self.savedNotice = nil }
                    )
                }

                if documents.isEmpty {
                    DocumentArchiveEmptyState(
                        hasActiveFilter: false,
                        onScan: presentScanner,
                        onClearFilters: clearFilters
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    DocumentArchiveControls(
                        searchText: $searchText,
                        selectedCategory: $selectedCategory,
                        documentCount: documents.count,
                        filteredCount: filteredDocuments.count,
                        hasActiveFilter: hasActiveFilter,
                        onClearFilters: clearFilters
                    )

                    if filteredDocuments.isEmpty {
                        DocumentArchiveEmptyState(
                            hasActiveFilter: true,
                            onScan: presentScanner,
                            onClearFilters: clearFilters
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredDocuments) { document in
                            NavigationLink(value: document.id) {
                                DocumentRow(document: document, searchText: searchText)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(document)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DocScanStyle.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DocScanStyle.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(DocScanStyle.blue)
            .navigationDestination(for: UUID.self) { documentID in
                if let document = documents.first(where: { $0.id == documentID }) {
                    DocumentDetailView(document: document)
                } else {
                    ContentUnavailableView(
                        "Document unavailable",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Return to the archive and try again.")
                    )
                }
            }
            .overlay {
                if isProcessingScan {
                    DocumentProcessingOverlay(pageCount: processingPageCount)
                }
            }
            .fullScreenCover(isPresented: $isScannerPresented) {
                DocumentScannerView(
                    onScan: handleScan,
                    onCancel: {},
                    onError: handleScanError
                )
                .ignoresSafeArea()
            }
            .alert("PaperIndex", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                #if DEBUG
                DebugPreviewData.seedIfRequested(in: modelContext)
                configurePreviewStateIfRequested()
                openPreviewDetailIfRequested()
                #endif
                presentInitialScannerIfNeeded()
            }
        }
        .preferredColorScheme(.light)
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

    private func clearFilters() {
        searchText = ""
        selectedCategory = .all
    }

    #if DEBUG
    private func configurePreviewStateIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments

        if let searchArgumentIndex = arguments.firstIndex(of: "-preview-search"),
           arguments.indices.contains(searchArgumentIndex + 1) {
            searchText = arguments[searchArgumentIndex + 1]
        }

        if arguments.contains("-show-processing-preview") {
            processingPageCount = 3
            isProcessingScan = true
        }

        guard arguments.contains("-show-saved-preview") else {
            return
        }

        var descriptor = FetchDescriptor<ScannedDocument>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let document = try? modelContext.fetch(descriptor).first {
            let locations = DocumentFileStore.availableLocations(folderName: document.fileStorageFolderName).available
            savedNotice = SavedDocumentNotice(
                title: document.title,
                storageSummary: storageSummary(for: locations)
            )
        }
    }

    private func openPreviewDetailIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-open-preview-detail") else {
            return
        }

        var descriptor = FetchDescriptor<ScannedDocument>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let document = try? modelContext.fetch(descriptor).first {
            navigationPath = [document.id]
        }
    }
    #endif

    private func handleScan(_ images: [UIImage]) {
        processingPageCount = images.count
        Task {
            await saveScan(images)
        }
    }

    private func handleScanError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    private func presentScanner() {
        guard VNDocumentCameraViewController.isSupported else {
            errorMessage = "Document scanning requires a physical iPhone or iPad with a camera."
            return
        }

        isScannerPresented = true
    }

    private func presentInitialScannerIfNeeded() {
        guard !hasPresentedInitialScanner,
              documents.isEmpty,
              VNDocumentCameraViewController.isSupported else {
            return
        }

        hasPresentedInitialScanner = true
        isScannerPresented = true
    }

    private func saveScan(_ images: [UIImage]) async {
        isProcessingScan = true
        defer { isProcessingScan = false }

        do {
            let processedPages = try await ScanProcessor.process(images: images)
            let fullText = processedPages
                .map(\.recognizedText)
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")

            let createdAt = Date()
            let metadata = DocumentMetadataService.ruleBasedMetadata(for: fullText, createdAt: createdAt)
            let pages = processedPages.map {
                ScannedPage(index: $0.index, imageData: $0.imageData, recognizedText: $0.recognizedText, createdAt: createdAt)
            }
            let documentID = UUID()

            let document = ScannedDocument(
                id: documentID,
                title: metadata.title,
                category: metadata.category.rawValue,
                fullText: fullText,
                documentSummary: metadata.summary,
                keywordsText: metadata.keywords.joined(separator: "\n"),
                fileStorageFolderName: DocumentFileStore.makeFolderName(title: metadata.title, createdAt: createdAt, id: documentID),
                createdAt: createdAt,
                updatedAt: createdAt,
                pageCount: pages.count,
                pages: pages
            )

            for page in pages {
                page.document = document
            }

            modelContext.insert(document)
            try modelContext.save()
            saveDocumentFiles(document)
            enrichDocument(document, fullText: fullText, fallback: metadata)
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func enrichDocument(_ document: ScannedDocument, fullText: String, fallback: DocumentMetadata) {
        Task { @MainActor in
            guard let metadata = await DocumentMetadataService.enrichedMetadata(for: fullText, fallback: fallback) else {
                return
            }

            do {
                document.applyMetadata(metadata)
                _ = try exportDocumentFiles(document)
                try modelContext.save()
            } catch {
                modelContext.rollback()
            }
        }
    }

    private func saveDocumentFiles(_ document: ScannedDocument) {
        do {
            let report = try exportDocumentFiles(document)
            try modelContext.save()
            savedNotice = SavedDocumentNotice(
                title: document.title,
                storageSummary: storageSummary(for: report.locations)
            )
        } catch {
            modelContext.rollback()
            errorMessage = "The scan was saved, but PaperIndex could not write the Files copies: \(error.localizedDescription)"
        }
    }

    private func exportDocumentFiles(_ document: ScannedDocument) throws -> DocumentFileExportReport {
        let package = DocumentFileStore.exportPackage(for: document)
        let report = try DocumentFileStore.export(package)
        document.filesExportedAt = report.exportedAt
        return report
    }

    private func storageSummary(for locations: [DocumentFileLocation]) -> String {
        let localTitle = locations.first(where: { $0.kind == .local })?.title ?? "On this device"

        if locations.contains(where: { $0.kind == .iCloud }) {
            return "Files · iCloud Drive + \(localTitle)"
        }

        return "Files · \(localTitle)"
    }

    private func delete(_ document: ScannedDocument) {
        do {
            modelContext.delete(document)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}

private struct SavedDocumentNotice {
    let title: String
    let storageSummary: String
}

#Preview {
    ContentView()
        .modelContainer(for: [ScannedDocument.self, ScannedPage.self], inMemory: true)
}
