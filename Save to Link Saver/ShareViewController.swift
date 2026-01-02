//
//  ShareViewController.swift
//  Save to Link Saver
//
//  Created by Burak on 2025/12/31.
//

import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {

    private var sharedURL: String?
    private var sharedTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Extract shared content
        extractSharedContent { [weak self] url, title in
            guard let self = self else { return }

            self.sharedURL = url
            self.sharedTitle = title

            DispatchQueue.main.async {
                self.presentShareView()
            }
        }
    }

    // MARK: - Extract Shared Content

    private func extractSharedContent(completion: @escaping (String?, String?) -> Void) {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            completion(nil, nil)
            return
        }

        // Create a local copy to avoid capturing issues
        let providers = Array(itemProviders)

        // Try to get JavaScript preprocessed data first (Safari)
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { [weak self] item, error in
                    guard let dict = item as? NSDictionary,
                          let results = dict[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else {
                        self?.extractURLFromProviders(providers, completion: completion)
                        return
                    }

                    let url = results["url"] as? String
                    let title = results["title"] as? String
                    completion(url, title)
                }
                return
            }
        }

        // Fallback: extract URL directly
        extractURLFromProviders(providers, completion: completion)
    }

    private func extractURLFromProviders(_ providers: [NSItemProvider], completion: @escaping (String?, String?) -> Void) {
        for provider in providers {
            // Try URL type
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                    if let url = item as? URL {
                        completion(url.absoluteString, nil)
                    } else if let urlData = item as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                        completion(url.absoluteString, nil)
                    } else {
                        completion(nil, nil)
                    }
                }
                return
            }

            // Try plain text (might be a URL)
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                    if let text = item as? String, let url = URL(string: text), url.scheme != nil {
                        completion(text, nil)
                    } else {
                        completion(nil, nil)
                    }
                }
                return
            }
        }

        completion(nil, nil)
    }

    // MARK: - Present SwiftUI View

    private func presentShareView() {
        let shareView = ShareView(
            url: sharedURL,
            title: sharedTitle,
            onSave: { [weak self] in
                self?.completeRequest()
            },
            onCancel: { [weak self] in
                self?.cancelRequest()
            }
        )

        let modelContainer = ModelContainerFactory.createContainer(for: ICloudSyncPreferences.isEnabled ? .iCloud : .local)
        let hostingController = UIHostingController(
            rootView: shareView.modelContainer(modelContainer)
        )

        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    // MARK: - Complete/Cancel

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func cancelRequest() {
        extensionContext?.cancelRequest(withError: NSError(domain: "com.linksaver", code: 0, userInfo: nil))
    }
}
