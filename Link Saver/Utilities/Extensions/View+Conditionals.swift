//
//  View+Conditionals.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

// MARK: - Conditional Glass Effect Modifiers
extension View {
    /// Applies Liquid Glass effect on iOS 26+, falls back to ultraThinMaterial on older versions
    @ViewBuilder
    func conditionalGlassEffect() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular)
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    /// Applies interactive Liquid Glass effect on iOS 26+, falls back to material on older versions
    @ViewBuilder
    func conditionalInteractiveGlass() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive())
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }

    /// Applies tinted glass effect with specified color
    @ViewBuilder
    func conditionalTintedGlass(_ color: Color) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.tint(color))
        } else {
            self
                .background(color.opacity(0.2))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Conditional Modifiers
extension View {
    /// Applies a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies one of two modifiers based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - iOS Version Checks
struct VersionCheck {
    static var supportsLiquidGlass: Bool {
        if #available(iOS 26, *) {
            return true
        }
        return false
    }
}
