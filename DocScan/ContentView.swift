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
    @State private var isScannerPresented = false
    @State private var isProcessingScan = false
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
        NavigationStack {
            List {
                DocumentArchiveControls(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    documentCount: documents.count,
                    filteredCount: filteredDocuments.count,
                    hasActiveFilter: hasActiveFilter,
                    onScan: presentScanner,
                    onClearFilters: clearFilters
                )

                if filteredDocuments.isEmpty {
                    DocumentArchiveEmptyState(
                        hasActiveFilter: hasActiveFilter,
                        onClearFilters: clearFilters
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredDocuments) { document in
                        NavigationLink {
                            DocumentDetailView(document: document)
                        } label: {
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DocScanStyle.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DocScanStyle.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppHeaderMark(onScan: presentScanner)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !documents.isEmpty {
                        FloatingIconButton(
                            systemImage: "camera.viewfinder",
                            accessibilityLabel: "Scan document",
                            action: presentScanner
                        )
                    }
                }
            }
            .overlay {
                if isProcessingScan {
                    DocumentProcessingOverlay()
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
            .alert("DocScan", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
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

    private func handleScan(_ images: [UIImage]) {
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
                try exportDocumentFiles(document)
                try modelContext.save()
            } catch {
                modelContext.rollback()
            }
        }
    }

    private func saveDocumentFiles(_ document: ScannedDocument) {
        do {
            try exportDocumentFiles(document)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "The scan was saved, but DocScan could not write the Files copies: \(error.localizedDescription)"
        }
    }

    private func exportDocumentFiles(_ document: ScannedDocument) throws {
        let package = DocumentFileStore.exportPackage(for: document)
        let report = try DocumentFileStore.export(package)
        document.filesExportedAt = report.exportedAt
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

#Preview {
    ContentView()
        .modelContainer(for: [ScannedDocument.self, ScannedPage.self], inMemory: true)
}
