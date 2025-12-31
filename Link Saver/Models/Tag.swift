//
//  Tag.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var dateCreated: Date
    @Transient private var cachedColorHex: String?
    @Transient private var cachedColor: Color?

    @Relationship(deleteRule: .nullify) var links: [Link]?

    // MARK: - Computed Properties
    var color: Color {
        if cachedColorHex == colorHex, let cachedColor {
            return cachedColor
        }

        let computed = Color(hex: colorHex) ?? .blue
        cachedColorHex = colorHex
        cachedColor = computed
        return computed
    }

    var linkCount: Int {
        links?.count ?? 0
    }

    // MARK: - Initialization
    init(name: String, colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.dateCreated = Date()
    }

    init(name: String, color: Color) {
        self.id = UUID()
        self.name = name
        self.colorHex = color.toHex() ?? "#007AFF"
        self.dateCreated = Date()
    }
}

// MARK: - Color Extension for Hex Conversion
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if length == 8 {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r

        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
