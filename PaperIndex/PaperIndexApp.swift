//
//  PaperIndexApp.swift
//  PaperIndex
//
//  Created by Homelab on 8/21/26.
//

import SwiftUI
import SwiftData

@main
struct PaperIndexApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            ScannedDocument.self,
            ScannedPage.self
        ])

        let configuration = ModelConfiguration(
            "DocScanStore",
            schema: schema,
            cloudKitDatabase: .private("iCloud.reactnativenerd.DocScan")
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create PaperIndex model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
