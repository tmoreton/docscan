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
            Text(hasActiveFilter ? "No Matches" : "No Documents Yet")
                .font(.title3.weight(.semibold))

            Text(hasActiveFilter ? "Try a different search or category." : "Scan a document to start your archive.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            if hasActiveFilter {
                Button(action: onClearFilters) {
                    Text("Clear Filters")
                        .frame(minWidth: 160)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
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
    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.black)

                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)

            Text("DocScan")
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .accessibilityLabel("DocScan")
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
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(.separator).opacity(0.4), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DocumentSearchField: View {
    @Binding var searchText: String

    var body: some View {
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
        .background(Color(red: 0.97, green: 0.97, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
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
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 8)

            CategoryFilterMenu(selectedCategory: $selectedCategory)

            if hasActiveFilter {
                Button("Clear", action: clearAction)
                    .font(.footnote.weight(.semibold))
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
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}
