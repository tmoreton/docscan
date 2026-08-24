//
//  DocumentArchiveChrome.swift
//  DocScan
//

import SwiftUI

struct DocumentArchiveControls: View {
    @Binding var searchText: String
    @Binding var selectedCategory: DocumentCategory

    let documentCount: Int
    let filteredCount: Int
    let hasActiveFilter: Bool
    let onScan: () -> Void
    let onClearFilters: () -> Void

    private var resultSummary: String {
        if hasActiveFilter {
            return "\(filteredCount) of \(documentCount)"
        }

        return "\(documentCount) document\(documentCount == 1 ? "" : "s")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if documentCount == 0 && !hasActiveFilter {
                PrimaryScanButton(action: onScan)
            }

            DocumentSearchField(searchText: $searchText)

            if documentCount > 0 {
                DocumentFilterSummary(
                    resultSummary: resultSummary,
                    hasActiveFilter: hasActiveFilter,
                    selectedCategory: $selectedCategory,
                    clearAction: onClearFilters
                )
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

struct DocumentArchiveEmptyState: View {
    let hasActiveFilter: Bool
    let onClearFilters: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle" : "doc.text.viewfinder")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(DocScanStyle.blue)
                .frame(width: 72, height: 72)
                .background(DocScanStyle.selectedSurface, in: Circle())
                .overlay {
                    Circle()
                        .stroke(DocScanStyle.border, lineWidth: 1)
                }

            Text(hasActiveFilter ? "No Matches" : "No Documents Yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(DocScanStyle.ink)

            Text(hasActiveFilter ? "Try a different search or category." : "Scan a document to start your archive.")
                .font(.body)
                .foregroundStyle(DocScanStyle.secondaryInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            if hasActiveFilter {
                Button(action: onClearFilters) {
                    Text("Clear Filters")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DocScanStyle.blue)
                        .frame(minWidth: 160)
                        .frame(height: 48)
                        .background(DocScanStyle.surface, in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(DocScanStyle.border, lineWidth: 1)
                        }
                        .shadow(color: DocScanStyle.shadow.opacity(0.65), radius: 14, x: 0, y: 8)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }
}

struct DocumentProcessingOverlay: View {
    var body: some View {
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
}

struct AppHeaderMark: View {
    var onScan: (() -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            Text("Docs")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(height: 44)
                .background(DocScanStyle.ink, in: Capsule())

            Button(action: { onScan?() }) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(DocScanStyle.blue)
                    .frame(width: 58)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .disabled(onScan == nil)
            .accessibilityLabel("Scan document")
        }
        .padding(6)
        .background(
            Capsule()
                .fill(DocScanStyle.surface)
                .shadow(color: DocScanStyle.shadow, radius: 18, x: 0, y: 10)
        )
        .overlay {
            Capsule()
                .stroke(DocScanStyle.border, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct PrimaryScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.title3.weight(.semibold))

                Text("Scan Document")
                    .font(.headline.weight(.semibold))

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 62)
            .foregroundStyle(.white)
            .background(DocScanStyle.scanGradient, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: DocScanStyle.blue.opacity(0.22), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct DocumentSearchField: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DocScanStyle.secondaryInk)

            TextField("Search documents", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(DocScanStyle.ink)

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
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
        .background(
            Capsule()
                .fill(DocScanStyle.surface)
                .shadow(color: DocScanStyle.shadow.opacity(0.85), radius: 16, x: 0, y: 8)
        )
        .overlay {
            Capsule()
                .stroke(DocScanStyle.border, lineWidth: 1)
        }
    }
}

private struct DocumentFilterSummary: View {
    let resultSummary: String
    let hasActiveFilter: Bool
    @Binding var selectedCategory: DocumentCategory
    let clearAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(resultSummary)
                .font(.footnote)
                .foregroundStyle(DocScanStyle.secondaryInk)
                .lineLimit(1)

            Spacer(minLength: 8)

            CategoryFilterMenu(selectedCategory: $selectedCategory)

            if hasActiveFilter {
                Button("Clear", action: clearAction)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DocScanStyle.blue)
                    .buttonStyle(.plain)
            }
        }
    }
}

private struct CategoryFilterMenu: View {
    @Binding var selectedCategory: DocumentCategory

    var body: some View {
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
            .foregroundStyle(DocScanStyle.ink)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(DocScanStyle.selectedSurface, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(DocScanStyle.strongBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
