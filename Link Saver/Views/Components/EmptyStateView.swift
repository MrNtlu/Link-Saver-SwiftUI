//
//  EmptyStateView.swift
//  Link Saver
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        EmptyStateView(
            title: "No Links",
            message: "Save links from Safari or other apps using the Share button.",
            systemImage: "link.badge.plus"
        )

        EmptyStateView(
            title: "No Folders",
            message: "Create folders to organize your saved links.",
            systemImage: "folder",
            actionTitle: "Create Folder"
        ) {
            print("Create folder tapped")
        }
    }
}
