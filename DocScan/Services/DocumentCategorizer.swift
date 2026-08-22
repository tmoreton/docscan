//
//  DocumentCategorizer.swift
//  DocScan
//

import Foundation

enum DocumentCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case receipts = "Receipts"
    case invoices = "Invoices"
    case tax = "Tax"
    case banking = "Banking"
    case medical = "Medical"
    case insurance = "Insurance"
    case legal = "Legal"
    case travel = "Travel"
    case utilities = "Utilities"
    case education = "Education"
    case identity = "Identity"
    case general = "General"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .all: "tray.full"
        case .receipts: "receipt"
        case .invoices: "doc.text"
        case .tax: "percent"
        case .banking: "building.columns"
        case .medical: "cross.case"
        case .insurance: "checkmark.shield"
        case .legal: "scale.3d"
        case .travel: "airplane"
        case .utilities: "bolt"
        case .education: "graduationcap"
        case .identity: "person.text.rectangle"
        case .general: "folder"
        }
    }

    static var filters: [DocumentCategory] {
        [.all] + allCases.filter { $0 != .all }
    }
}

enum DocumentCategorizer {
    private struct Definition {
        let category: DocumentCategory
        let keywords: [String]
    }

    private static let definitions: [Definition] = [
        .init(category: .receipts, keywords: ["receipt", "subtotal", "total", "change", "cashier", "payment", "paid", "visa", "mastercard", "amex", "store"]),
        .init(category: .invoices, keywords: ["invoice", "amount due", "balance due", "bill to", "invoice number", "terms", "net 30", "remit"]),
        .init(category: .tax, keywords: ["tax", "irs", "1040", "w-2", "w2", "1099", "deduction", "return", "taxpayer", "ein"]),
        .init(category: .banking, keywords: ["bank", "statement", "account", "routing", "deposit", "withdrawal", "checking", "savings", "transaction"]),
        .init(category: .medical, keywords: ["patient", "diagnosis", "clinic", "hospital", "physician", "doctor", "prescription", "rx", "medical", "lab"]),
        .init(category: .insurance, keywords: ["insurance", "policy", "claim", "coverage", "premium", "deductible", "beneficiary", "insured"]),
        .init(category: .legal, keywords: ["agreement", "contract", "court", "attorney", "legal", "signature", "notary", "terms and conditions"]),
        .init(category: .travel, keywords: ["boarding pass", "flight", "hotel", "reservation", "itinerary", "departure", "arrival", "gate", "ticket"]),
        .init(category: .utilities, keywords: ["utility", "electric", "water", "gas", "internet", "phone", "kilowatt", "kwh", "meter", "service address"]),
        .init(category: .education, keywords: ["school", "university", "student", "transcript", "tuition", "course", "grade", "semester"]),
        .init(category: .identity, keywords: ["passport", "driver license", "identification", "date of birth", "dob", "social security", "ssn"])
    ]

    static func inferCategory(from text: String) -> DocumentCategory {
        let normalized = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        var bestMatch: (category: DocumentCategory, score: Int) = (.general, 0)

        for definition in definitions {
            let score = definition.keywords.reduce(0) { partialResult, keyword in
                partialResult + (normalized.contains(keyword) ? keywordScore(for: keyword) : 0)
            }

            if score > bestMatch.score {
                bestMatch = (definition.category, score)
            }
        }

        return bestMatch.score >= 2 ? bestMatch.category : .general
    }

    static func makeTitle(from text: String, createdAt: Date) -> String {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                line.count >= 3 && !line.allSatisfy { $0.isNumber || $0.isWhitespace || $0.isPunctuation }
            }

        if let candidate = lines.first {
            return String(candidate.prefix(64))
        }

        return "Scan \(createdAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private static func keywordScore(for keyword: String) -> Int {
        keyword.contains(" ") ? 2 : 1
    }
}
