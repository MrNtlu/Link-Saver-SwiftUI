//
//  TagChip.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

struct TagChip: View {
    let tag: Tag
    let isCompact: Bool

    init(tag: Tag, isCompact: Bool = false) {
        self.tag = tag
        self.isCompact = isCompact
    }

    var body: some View {
        if isCompact {
            compactChip
        } else {
            regularChip
        }
    }

    private var compactChip: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.color)
                .frame(width: 6, height: 6)

            Text(tag.name)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(tag.color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var regularChip: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tag.color)
                .frame(width: 8, height: 8)

            Text(tag.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tag.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            TagChip(tag: Tag(name: "Important", colorHex: "#FF3B30"), isCompact: true)
            TagChip(tag: Tag(name: "Tech", colorHex: "#007AFF"), isCompact: true)
            TagChip(tag: Tag(name: "News", colorHex: "#34C759"), isCompact: true)
        }

        HStack {
            TagChip(tag: Tag(name: "Important", colorHex: "#FF3B30"), isCompact: false)
            TagChip(tag: Tag(name: "Tech", colorHex: "#007AFF"), isCompact: false)
        }
    }
    .padding()
}
