//
//  DocScanStyle.swift
//  DocScan
//

import SwiftUI

enum DocScanStyle {
    static let background = Color(red: 0.948, green: 0.963, blue: 0.965)
    static let surface = Color(red: 0.997, green: 0.999, blue: 1.000)
    static let mutedSurface = Color(red: 0.910, green: 0.929, blue: 0.932)
    static let selectedSurface = Color(red: 0.890, green: 0.940, blue: 0.980)
    static let ink = Color(red: 0.075, green: 0.083, blue: 0.098)
    static let secondaryInk = Color(red: 0.392, green: 0.420, blue: 0.455)
    static let blue = Color(red: 0.000, green: 0.365, blue: 0.760)
    static let teal = Color(red: 0.000, green: 0.520, blue: 0.475)
    static let border = Color(red: 0.145, green: 0.160, blue: 0.180).opacity(0.12)
    static let strongBorder = Color(red: 0.145, green: 0.160, blue: 0.180).opacity(0.20)
    static let shadow = Color(red: 0.055, green: 0.065, blue: 0.080).opacity(0.12)
    static let scanGradient = LinearGradient(
        colors: [
            Color(red: 0.000, green: 0.365, blue: 0.760),
            Color(red: 0.000, green: 0.520, blue: 0.475)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func categoryTint(for category: String) -> Color {
        switch DocumentCategory(rawValue: category) {
        case .receipts, .tax:
            return Color(red: 0.805, green: 0.355, blue: 0.055)
        case .invoices, .banking:
            return blue
        case .medical, .insurance:
            return Color(red: 0.685, green: 0.115, blue: 0.275)
        case .legal, .identity:
            return Color(red: 0.420, green: 0.255, blue: 0.690)
        case .travel, .education:
            return teal
        case .utilities:
            return Color(red: 0.585, green: 0.430, blue: 0.075)
        default:
            return secondaryInk
        }
    }
}

struct FloatingIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(DocScanStyle.blue)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(DocScanStyle.surface)
                        .shadow(color: DocScanStyle.shadow, radius: 18, x: 0, y: 10)
                )
                .overlay {
                    Circle()
                        .stroke(DocScanStyle.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
