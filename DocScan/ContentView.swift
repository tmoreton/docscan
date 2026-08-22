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

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    searchControls

                    if filteredDocuments.isEmpty {
                        emptyState
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
                            .listRowSeparator(.visible)
                            .listRowSeparatorTint(Color(.separator).opacity(0.35))
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
                .background(Color.white)
            }
            .background(Color.white)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppHeaderMark()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !documents.isEmpty {
                        Button {
                            presentScanner()
                        } label: {
                            Label("Scan", systemImage: "camera.viewfinder")
                        }
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
        .preferredColorScheme(.light)
    }

    private var filteredDocuments: [ScannedDocument] {
        documents.filter { document in
            let matchesCategory = selectedCategory == .all || document.category == selectedCategory.rawValue
            return matchesCategory && DocumentSearch.matches(query: searchText, document: document)
        }
    }

    private var hasActiveFilter: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCategory != .all
    }

    private var searchControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            if documents.isEmpty && !hasActiveFilter {
                primaryScanButton
            }

            searchField

            if !documents.isEmpty {
                filterSummary
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var primaryScanButton: some View {
        Button {
            presentScanner()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.title3.weight(.semibold))

                Text("Scan Document")
                    .font(.headline.weight(.semibold))

                Spacer(minLength: 8)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search documents", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 48)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        }
    }

    private var filterSummary: some View {
        HStack(spacing: 10) {
            Text(resultSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 8)

            categoryFilter

            if hasActiveFilter {
                Button("Clear") {
                    clearFilters()
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
            }
        }
    }

    private var categoryFilter: some View {
        Menu {
            ForEach(DocumentCategory.filters) { category in
                Button {
                    selectedCategory = category
                } label: {
                    Text(category.rawValue)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedCategory.rawValue)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private var resultSummary: String {
        let totalCount = documents.count
        let filteredCount = filteredDocuments.count

        if hasActiveFilter {
            return "\(filteredCount) of \(totalCount)"
        }

        return "\(totalCount) document\(totalCount == 1 ? "" : "s")"
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text(hasActiveFilter ? "No Matches" : "No Documents Yet")
                .font(.title3.weight(.semibold))

            Text(hasActiveFilter ? "Try a different search or category." : "Scan a document to start your archive.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            if hasActiveFilter {
                Button {
                    clearFilters()
                } label: {
                    Text("Clear Filters")
                        .frame(minWidth: 160)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                Text("Saving scan")
                    .font(.headline)
            }
            .padding(24)
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

    private func clearFilters() {
        searchText = ""
        selectedCategory = .all
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

            let document = ScannedDocument(
                title: metadata.title,
                category: metadata.category.rawValue,
                fullText: fullText,
                documentSummary: metadata.summary,
                keywordsText: metadata.keywords.joined(separator: "\n"),
                metadataSource: metadata.source.rawValue,
                metadataUpdatedAt: createdAt,
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
            enrichDocument(document, fullText: fullText, createdAt: createdAt)
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func enrichDocument(_ document: ScannedDocument, fullText: String, createdAt: Date) {
        Task { @MainActor in
            let metadata = await DocumentMetadataService.enrichedMetadata(for: fullText, createdAt: createdAt)

            guard metadata.source == .appleIntelligence else {
                return
            }

            do {
                document.applyMetadata(metadata)
                try modelContext.save()
            } catch {
                modelContext.rollback()
            }
        }
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

private struct AppHeaderMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.accentColor)

            Image(systemName: "doc.viewfinder")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 32, height: 32)
        .accessibilityLabel("DocScan")
    }
}
