//
//  DocumentArchiveChrome.swift
//  PaperIndex
//

import SwiftUI

struct DocumentArchiveHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let documentCount: Int
    let onScan: () -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    title
                    ArchiveScanButton(action: onScan)
                }
            } else {
                HStack(alignment: .center, spacing: 16) {
                    title
                    Spacer(minLength: 8)
                    ArchiveScanButton(action: onScan)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Documents")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(PaperIndexStyle.ink)

            Text(documentCount == 0 ? "Your searchable archive" : "\(documentCount) saved and searchable")
                .font(.subheadline)
                .foregroundStyle(PaperIndexStyle.secondaryInk)
        }
    }
}

struct DocumentArchiveControls: View {
    @Binding var searchText: String
    @Binding var selectedCategory: DocumentCategory

    let documentCount: Int
    let filteredCount: Int
    let hasActiveFilter: Bool
    let onClearFilters: () -> Void

    private var resultSummary: String {
        if hasActiveFilter {
            return "Showing \(filteredCount) of \(documentCount)"
        }

        return "\(documentCount) document\(documentCount == 1 ? "" : "s")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DocumentSearchField(searchText: $searchText)

            DocumentFilterSummary(
                resultSummary: resultSummary,
                hasActiveFilter: hasActiveFilter,
                selectedCategory: $selectedCategory,
                clearAction: onClearFilters
            )
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

struct DocumentArchiveEmptyState: View {
    let hasActiveFilter: Bool
    let onScan: () -> Void
    let onClearFilters: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease" : "doc.viewfinder")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(PaperIndexStyle.darkSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(spacing: 8) {
                Text(hasActiveFilter ? "No matching documents" : "Paper in. Clarity out.")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(PaperIndexStyle.ink)

                Text(
                    hasActiveFilter
                        ? "Try a different search or category."
                        : "Scan a document to make it searchable and save a clear copy in Files."
                )
                .font(.body)
                .foregroundStyle(PaperIndexStyle.secondaryInk)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 310)
            }

            if hasActiveFilter {
                Button("Clear filters", action: onClearFilters)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PaperIndexStyle.blue)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 50)
                    .background(PaperIndexStyle.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(PaperIndexStyle.border, lineWidth: 1)
                    }
            } else {
                PrimaryScanButton(title: "Scan first document", action: onScan)
                    .frame(maxWidth: 340)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                    Text("On-device text recognition")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(PaperIndexStyle.tertiaryInk)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 34)
        .frame(maxWidth: .infinity, minHeight: 460)
        .background(PaperIndexStyle.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(PaperIndexStyle.border, lineWidth: 1)
        }
        .shadow(color: PaperIndexStyle.shadow, radius: 18, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct DocumentSavedNotice: View {
    let title: String
    let storageSummary: String
    let dismissAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(PaperIndexStyle.blue, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Saved and searchable")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PaperIndexStyle.ink)

                Text("\(title) · \(storageSummary)")
                    .font(.caption)
                    .foregroundStyle(PaperIndexStyle.secondaryInk)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Button(action: dismissAction) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PaperIndexStyle.secondaryInk)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss saved message")
        }
        .padding(14)
        .background(PaperIndexStyle.selectedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PaperIndexStyle.blue.opacity(0.22), lineWidth: 1)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

struct DocumentProcessingOverlay: View {
    let pageCount: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.26)

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(PaperIndexStyle.blue)

                VStack(spacing: 5) {
                    Text("Saving \(pageCount) page\(pageCount == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(PaperIndexStyle.ink)

                    Text("Recognizing text and creating your Files copies.")
                        .font(.subheadline)
                        .foregroundStyle(PaperIndexStyle.secondaryInk)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .padding(24)
            .frame(maxWidth: 290)
            .background(PaperIndexStyle.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(PaperIndexStyle.border, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.16), radius: 28, x: 0, y: 14)
        }
    }
}

struct ArchiveScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "camera.viewfinder")
                Text("Scan")
            }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minHeight: 42)
                .background(PaperIndexStyle.blue, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan document")
    }
}

private struct PrimaryScanButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.title3.weight(.semibold))

                Text(title)
                    .font(.headline.weight(.semibold))

                Spacer(minLength: 8)

                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.bold))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(.white)
            .background(PaperIndexStyle.blue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: PaperIndexStyle.blue.opacity(0.20), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct DocumentSearchField: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(PaperIndexStyle.secondaryInk)

            TextField("Search titles or recognized text", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(PaperIndexStyle.ink)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(PaperIndexStyle.tertiaryInk)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 15)
        .frame(minHeight: 52)
        .background(PaperIndexStyle.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(PaperIndexStyle.border, lineWidth: 1)
        }
        .shadow(color: PaperIndexStyle.shadow.opacity(0.7), radius: 10, x: 0, y: 5)
    }
}

private struct DocumentFilterSummary: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let resultSummary: String
    let hasActiveFilter: Bool
    @Binding var selectedCategory: DocumentCategory
    let clearAction: () -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    resultLabel
                    filterControls
                }
            } else {
                HStack(spacing: 10) {
                    resultLabel
                    Spacer(minLength: 8)
                    filterControls
                }
            }
        }
    }

    private var resultLabel: some View {
        Text(resultSummary)
            .font(.footnote.weight(.medium))
            .foregroundStyle(PaperIndexStyle.secondaryInk)
    }

    private var filterControls: some View {
        HStack(spacing: 10) {
            CategoryFilterMenu(selectedCategory: $selectedCategory)

            if hasActiveFilter {
                Button("Clear", action: clearAction)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PaperIndexStyle.blue)
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
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.caption.weight(.semibold))
                Text(selectedCategory.rawValue)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(PaperIndexStyle.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minHeight: 36)
            .background(PaperIndexStyle.surface, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(PaperIndexStyle.strongBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
