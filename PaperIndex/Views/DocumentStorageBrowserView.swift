//
//  DocumentStorageBrowserView.swift
//  PaperIndex
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentStorageBrowserView: UIViewControllerRepresentable {
    let directoryURL: URL

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: false)
        controller.directoryURL = directoryURL
        controller.allowsMultipleSelection = false
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }
}
