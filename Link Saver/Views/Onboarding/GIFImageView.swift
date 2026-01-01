//
//  GIFImageView.swift
//  Link Saver
//
//  Created by Codex on 2026/01/01.
//

import SwiftUI
import UIKit
import ImageIO

struct GIFImageView: UIViewRepresentable {
    let dataAssetName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear

        if let dataAsset = NSDataAsset(name: dataAssetName),
           let animatedImage = UIImage.animatedGIF(dataAsset.data) {
            imageView.image = animatedImage
        }

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        CGSize(
            width: proposal.width ?? uiView.intrinsicContentSize.width,
            height: proposal.height ?? uiView.intrinsicContentSize.height
        )
    }
}

private extension UIImage {
    static func animatedGIF(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else { return nil }

        var images: [UIImage] = []
        images.reserveCapacity(frameCount)

        var duration: TimeInterval = 0

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            let frameDuration = gifFrameDuration(source: source, index: index)
            duration += frameDuration
            images.append(UIImage(cgImage: cgImage))
        }

        if duration <= 0 {
            duration = Double(images.count) * 0.1
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }

    static func gifFrameDuration(source: CGImageSource, index: Int) -> TimeInterval {
        let defaultFrameDuration: TimeInterval = 0.1
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifInfo = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return defaultFrameDuration
        }

        let unclamped = gifInfo[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let clamped = gifInfo[kCGImagePropertyGIFDelayTime] as? TimeInterval
        let duration = unclamped ?? clamped ?? defaultFrameDuration

        return duration < 0.02 ? defaultFrameDuration : duration
    }
}
