//
//  OCRTextFormatter.swift
//  PaperIndex
//

import Foundation

enum OCRTextFormatter {
    nonisolated static func formattedText(
        from pageTexts: [String],
        fallback: String = "",
        includePageHeadings: Bool = false
    ) -> String {
        var formattedPages: [(pageNumber: Int, text: String)] = []

        for (index, pageText) in pageTexts.enumerated() {
            let text = formattedText(from: pageText)
            if !text.isEmpty {
                formattedPages.append((index + 1, text))
            }
        }

        if formattedPages.isEmpty {
            let fallbackText = formattedText(from: fallback)
            return fallbackText
        }

        return formattedPages.map { page in
            guard includePageHeadings, formattedPages.count > 1 else {
                return page.text
            }

            return "Page \(page.pageNumber)\n\(page.text)"
        }
        .joined(separator: "\n\n")
    }

    nonisolated static func formattedText(from rawText: String) -> String {
        let lines = rawText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map(cleanedLine)

        var blocks: [String] = []
        var currentBlock = ""
        var previousLine = ""

        func flushBlock() {
            let block = currentBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            if !block.isEmpty {
                blocks.append(block)
            }
            currentBlock = ""
            previousLine = ""
        }

        for line in lines {
            if line.isEmpty {
                flushBlock()
                continue
            }

            guard !currentBlock.isEmpty else {
                currentBlock = line
                previousLine = line
                continue
            }

            if shouldStartNewBlock(after: previousLine, before: line) {
                flushBlock()
                currentBlock = line
            } else {
                currentBlock += " " + line
            }

            previousLine = line
        }

        flushBlock()
        return blocks.joined(separator: "\n\n")
    }

    nonisolated private static func cleanedLine(_ line: String) -> String {
        line
            .replacingOccurrences(of: "\t", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func shouldStartNewBlock(after previousLine: String, before currentLine: String) -> Bool {
        if isListItem(previousLine) || isListItem(currentLine) {
            return true
        }

        if isLedgerLine(previousLine) || isLedgerLine(currentLine) {
            return true
        }

        if isFieldLine(previousLine) || isFieldLine(currentLine) {
            return true
        }

        if looksLikeHeading(previousLine) || looksLikeHeading(currentLine) {
            return true
        }

        return endsSentence(previousLine) && startsWithUppercaseLetter(currentLine)
    }

    nonisolated private static func isListItem(_ line: String) -> Bool {
        line.range(of: #"^([0-9]+[\.\)]|[A-Za-z][\.\)]|[-*])\s+\S+"#, options: .regularExpression) != nil
    }

    nonisolated private static func isLedgerLine(_ line: String) -> Bool {
        let hasAmount = line.range(of: #"\b\d[\d,]*\.\d{2}\b"#, options: .regularExpression) != nil
        let hasCurrency = line.contains("$")
        return hasAmount || hasCurrency
    }

    nonisolated private static func isFieldLine(_ line: String) -> Bool {
        guard line.count <= 90,
              let colonIndex = line.firstIndex(of: ":") else {
            return false
        }

        let label = String(line[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        return !label.isEmpty && label.count <= 36
    }

    nonisolated private static func looksLikeHeading(_ line: String) -> Bool {
        let words = line.split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty,
              words.count <= 6,
              line.count <= 54,
              !line.contains("."),
              !line.contains(",") else {
            return false
        }

        let letters = line.filter(\.isLetter)
        guard letters.count >= 3 else {
            return false
        }

        let uppercaseLetters = letters.filter(\.isUppercase)
        if uppercaseLetters.count >= max(3, letters.count * 7 / 10) {
            return true
        }

        return words.count <= 3 && startsWithUppercaseLetter(line)
    }

    nonisolated private static func endsSentence(_ line: String) -> Bool {
        guard let last = line.last else {
            return false
        }

        return ".!?".contains(last)
    }

    nonisolated private static func startsWithUppercaseLetter(_ line: String) -> Bool {
        guard let firstLetter = line.first(where: \.isLetter) else {
            return false
        }

        return firstLetter.isUppercase
    }
}
