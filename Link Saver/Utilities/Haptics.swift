//
//  Haptics.swift
//  Link Saver
//
//  Created by Claude on 2026/01/05.
//

import UIKit

enum Haptics {
    @MainActor
    static func selectionChanged() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @MainActor
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    @MainActor
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

