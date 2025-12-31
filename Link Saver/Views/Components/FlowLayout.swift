//
//  FlowLayout.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// A layout that arranges views in a flowing manner, wrapping to new lines as needed
struct FlowLayout: Layout {
    var spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)

                if currentX + viewSize.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))

                currentX += viewSize.width + spacing
                maxX = max(maxX, currentX)
                lineHeight = max(lineHeight, viewSize.height)
            }

            size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}

#Preview {
    FlowLayout(spacing: 8) {
        ForEach(0..<10) { index in
            Text("Tag \(index)")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
        }
    }
    .padding()
}
