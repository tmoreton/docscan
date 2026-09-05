# PaperIndex

**A private, searchable document scanner for iPhone and iPad.**

[Website](https://tmoreton.github.io/PaperIndex/) · [Privacy](https://tmoreton.github.io/PaperIndex/privacy/) · [Terms](https://tmoreton.github.io/PaperIndex/terms/)

PaperIndex turns receipts, statements, forms, and notes into a calm, searchable archive. It captures pages with Apple's document camera, recognizes their text on-device, organizes them, and writes understandable copies to Files.

## Privacy at a glance

PaperIndex does not operate a server and does not include analytics, advertising, tracking, or third-party SDKs. It does not create an account or send scans, recognized text, or document metadata to the PaperIndex developers.

- Scanning uses Apple's native `VisionKit` document camera.
- OCR uses Apple's `Vision` framework on the device.
- Titles, summaries, keywords, and categories use Apple's on-device Foundation Models when available, with a local rule-based fallback.
- Search runs locally against the saved document index.
- Documents are stored in the app's SwiftData library and exported to Files.
- When the user enables iCloud, Apple may sync the private SwiftData store through CloudKit and Files copies through the user's private iCloud Drive account.

In short: **document processing stays on the device, and no document data is sent to a PaperIndex-controlled service.** Optional iCloud syncing is handled by Apple under the user's Apple Account settings.

See the full [Privacy Policy](https://tmoreton.github.io/PaperIndex/privacy/) for storage and deletion details.

## What it does

1. Captures and crops one or more pages with the system document scanner.
2. Recognizes text locally and preserves a high-quality JPEG for each page.
3. Creates a title and category immediately, then enriches metadata on supported devices.
4. Saves a searchable library record and exports page images plus OCR text to Files.
5. Searches titles, summaries, categories, keywords, and recognized page text.

## Technology

| Technology | How PaperIndex uses it |
| --- | --- |
| Swift 5 and SwiftUI | Native app structure and accessible interface |
| VisionKit | Multi-page document capture and automatic page cropping |
| Vision | Accurate, language-aware on-device text recognition |
| Foundation Models | On-device title, summary, keyword, and category enrichment when supported |
| SwiftData | Local document, page, and searchable metadata persistence |
| CloudKit | Optional sync of the private SwiftData database through the user's iCloud account |
| iCloud Drive and FileManager | User-visible page images, document information, and OCR text exports |
| Core Spotlight attributes | Makes selected stored metadata eligible for system indexing |
| UIKit and Uniform Type Identifiers | Image handling and Files integration |

There are no third-party runtime dependencies.

## Data flow

```text
Camera
  └─> VisionKit page capture
       └─> Vision OCR (on device)
            └─> local categorization / Foundation Models (on device)
                 ├─> SwiftData library on this device
                 ├─> Files export on this device
                 └─> optional private iCloud sync controlled by the user
```

PaperIndex contains no application networking layer. Apple system frameworks may communicate with iCloud only when the user has enabled the relevant iCloud services.

## Requirements

- Xcode with the iOS 26.5 SDK
- iOS or iPadOS 26.5 or later
- An iPhone or iPad camera for live document capture
- A supported Apple Intelligence device for Foundation Models enrichment; core scanning, OCR, rule-based categorization, storage, and search continue to work without it

## Build

Open `DocScan.xcodeproj` in Xcode and run the `DocScan` scheme, or build from Terminal:

```sh
xcodebuild \
  -project DocScan.xcodeproj \
  -scheme DocScan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

The Xcode project and internal target still use the original `DocScan` identifier to preserve the shipping app's bundle and iCloud container identity. The customer-facing product name is PaperIndex.

## Project structure

```text
DocScan/
├── Models/       SwiftData document and page models
├── Services/     OCR, metadata, search, scan processing, and Files export
├── Views/        SwiftUI archive, detail, scanner, and storage views
└── ContentView.swift

docs/             GitHub Pages website, privacy policy, and terms
```

## Contributing

Issues and focused pull requests are welcome. Please avoid including real scans, OCR text, account numbers, health information, or other sensitive data in bug reports and test fixtures.

Before submitting a change, build the app for an iPhone simulator and an iPad simulator and verify the affected flow.

## License

An open-source license has not yet been selected. Until a `LICENSE` file is added, standard copyright applies even though the repository is public. Choose an OSI-approved license before distributing modified versions.

