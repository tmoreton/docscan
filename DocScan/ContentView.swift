//
//  ContentView.swift
//  DocScan
//
//  Created by Homelab on 8/21/26.
//

import SwiftUI
import SwiftData
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

    var body: some View {
        NavigationStack {
            List {
                if filteredDocuments.isEmpty {
                    emptyState
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredDocuments) { document in
                        NavigationLink {
                            DocumentDetailView(document: document)
                        } label: {
                            DocumentRow(document: document)
                        }
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
            .navigationTitle("DocScan")
            .searchable(text: $searchText, prompt: "Search text, title, or category")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    categoryFilter
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentScanner()
                    } label: {
                        Label("Scan", systemImage: "doc.viewfinder")
                    }
                }
            }
            .overlay {
                if isProcessingScan {
                    processingOverlay
                }
            }
            .fullScreenCover(isPresented: $isScannerPresented) {
                DocumentScannerView(
                    onScan: { images in
                        Task {
                            await saveScan(images)
                        }
                    },
                    onCancel: {},
                    onError: { error in
                        errorMessage = error.localizedDescription
                    }
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
    }

    private var filteredDocuments: [ScannedDocument] {
        documents.filter { document in
            let matchesCategory = selectedCategory == .all || document.category == selectedCategory.rawValue

            guard matchesCategory else {
                return false
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else {
                return true
            }

            let searchableText = [
                document.title,
                document.category,
                document.fullText
            ]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

            return searchableText.contains(query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current))
        }
    }

    private var categoryFilter: some View {
        Menu {
            ForEach(DocumentCategory.filters) { category in
                Button {
                    selectedCategory = category
                } label: {
                    Label(category.rawValue, systemImage: category.iconName)
                }
            }
        } label: {
            Label(selectedCategory.rawValue, systemImage: selectedCategory.iconName)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("No Documents")
                    .font(.title2.weight(.semibold))

                Text(searchText.isEmpty ? "Scan a document to create your searchable archive." : "No documents match this search.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            Button {
                presentScanner()
            } label: {
                Label("Scan Document", systemImage: "camera.viewfinder")
                    .frame(minWidth: 180)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                Text("Reading document")
                    .font(.headline)
                Text("OCR and categorization are running on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
            let category = DocumentCategorizer.inferCategory(from: fullText)
            let title = DocumentCategorizer.makeTitle(from: fullText, createdAt: createdAt)
            let pages = processedPages.map {
                ScannedPage(index: $0.index, imageData: $0.imageData, recognizedText: $0.recognizedText, createdAt: createdAt)
            }

            let document = ScannedDocument(
                title: title,
                category: category.rawValue,
                fullText: fullText,
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ document: ScannedDocument) {
        modelContext.delete(document)
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ScannedDocument.self, ScannedPage.self], inMemory: true)
}
