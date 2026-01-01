//
//  TagFilterView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

struct TagFilterView: View {
    let tags: [Tag]
    @Binding var selectedTag: Tag?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All filter
                FilterChip(
                    title: Text("tagFilter.all"),
                    color: selectedTag == nil ? .blue : .secondary,
                    isSelected: selectedTag == nil
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTag = nil
                    }
                }

                // Tag filters
                ForEach(tags) { tag in
                    FilterChip(
                        title: Text(verbatim: tag.name),
                        color: tag.color,
                        isSelected: selectedTag?.id == tag.id
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedTag?.id == tag.id {
                                selectedTag = nil
                            } else {
                                selectedTag = tag
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: Text
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Circle()
                        .fill(isSelected ? .white : color)
                        .frame(width: 8, height: 8)
                }

                title
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.15))
            .foregroundStyle(isSelected ? .white : color)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTag: Tag?

        let tags = [
            Tag(name: "Important", colorHex: "#FF3B30"),
            Tag(name: "Tech", colorHex: "#007AFF"),
            Tag(name: "News", colorHex: "#34C759"),
            Tag(name: "Work", colorHex: "#FF9500")
        ]

        var body: some View {
            VStack {
                TagFilterView(tags: tags, selectedTag: $selectedTag)

                if let tag = selectedTag {
                    Text("Selected: \(tag.name)")
                } else {
                    Text("All selected")
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
