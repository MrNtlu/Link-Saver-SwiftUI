//
//  PersistenceController.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class PersistenceController: ObservableObject {
    @Published private(set) var container: ModelContainer
    @Published private(set) var containerID = UUID()
    @Published private(set) var isSwitchingSyncMode = false

    init() {
        self.container = ModelContainerFactory.createContainer(for: ICloudSyncPreferences.isEnabled ? .iCloud : .local)
    }

    var isICloudSyncEnabled: Bool {
        ICloudSyncPreferences.isEnabled
    }

    func setICloudSyncEnabled(_ enabled: Bool) async {
        guard enabled != ICloudSyncPreferences.isEnabled else { return }
        guard !isSwitchingSyncMode else { return }

        isSwitchingSyncMode = true
        defer { isSwitchingSyncMode = false }

        let sourceMode: ModelContainerFactory.SyncMode = ICloudSyncPreferences.isEnabled ? .iCloud : .local
        let destinationMode: ModelContainerFactory.SyncMode = enabled ? .iCloud : .local

        do {
            try DataMergeService.merge(
                from: ModelContainerFactory.createContainer(for: sourceMode),
                to: ModelContainerFactory.createContainer(for: destinationMode)
            )

            ICloudSyncPreferences.isEnabled = enabled
            container = ModelContainerFactory.createContainer(for: enabled ? .iCloud : .local)
            containerID = UUID()
        } catch {
            // Keep current mode on failure.
            print("[LinkSaver] Failed to switch iCloud sync mode: \(error.localizedDescription)")
        }
    }
}
