//
//  InfoView.swift
//  Disco
//
//  Created by Alex Cruz on 18/01/2026.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let text = loadAboutText() {
                        MarkdownBlocksView(markdown: text)
                    } else {
                        Text("Failed to load About.md")
                            .font(.body)
                            .opacity(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func loadAboutText() -> String? {
        guard let url = Bundle.main.url(forResource: "About", withExtension: "md") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

// MARK: - Minimal Markdown rendering (headings + bullets + paragraphs)

private struct MarkdownBlocksView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(parse(markdown)) { block in
                switch block.kind {
                case .h1(let text):
                    Text(text)
                        .font(.title.weight(.semibold))

                case .h2(let text):
                    Text(text)
                        .font(.title3.weight(.semibold))
                        .padding(.top, 6)

                case .bullet(let text):
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("•")
                        Text(text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.body)
                    .opacity(0.92)

                case .paragraph(let text):
                    Text(text)
                        .font(.body)
                        .opacity(0.88)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Parser

    private struct Block: Identifiable {
        enum Kind {
            case h1(String)
            case h2(String)
            case bullet(String)
            case paragraph(String)
        }

        let id = UUID()
        let kind: Kind
    }

    private func parse(_ md: String) -> [Block] {
        let lines = md
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        var blocks: [Block] = []
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            let text = paragraphBuffer
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if !text.isEmpty {
                blocks.append(Block(kind: .paragraph(text)))
            }
            paragraphBuffer.removeAll()
        }

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
                continue
            }

            if line.hasPrefix("# ") {
                flushParagraph()
                blocks.append(Block(kind: .h1(String(line.dropFirst(2)))))
                continue
            }

            if line.hasPrefix("## ") {
                flushParagraph()
                blocks.append(Block(kind: .h2(String(line.dropFirst(3)))))
                continue
            }

            if line.hasPrefix("- ") {
                flushParagraph()
                blocks.append(Block(kind: .bullet(String(line.dropFirst(2)))))
                continue
            }

            paragraphBuffer.append(line)
        }

        flushParagraph()
        return blocks
    }
}

#Preview {
    InfoView()
}
