//
//  DocScanStyle.swift
//  DocScan
//

import SwiftUI

enum DocScanStyle {
    static let background = Color.white
    static let surface = Color.white
    static let selectedSurface = Color(red: 0.925, green: 0.925, blue: 0.918)
    static let ink = Color(red: 0.055, green: 0.055, blue: 0.055)
    static let secondaryInk = Color(red: 0.44, green: 0.44, blue: 0.44)
    static let blue = Color(red: 0.03, green: 0.54, blue: 0.96)
    static let border = Color.black.opacity(0.06)
    static let shadow = Color.black.opacity(0.10)
}

struct FloatingIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(DocScanStyle.ink)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(DocScanStyle.surface)
                        .shadow(color: DocScanStyle.shadow, radius: 18, x: 0, y: 10)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
