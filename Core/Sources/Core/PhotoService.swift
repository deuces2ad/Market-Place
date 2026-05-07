//
//  PhotoService.swift
//  Core
//

import UIKit
import Foundation

public final class PhotoService {

    public static let shared = PhotoService()

    private let fileManager = FileManager.default
    private let imageDirectory: URL

    private init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        imageDirectory = documentsURL.appendingPathComponent("ListingImages", isDirectory: true)

        if !fileManager.fileExists(atPath: imageDirectory.path) {
            try? fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        }
    }

    /// Saves a UIImage to the local documents directory and returns the file path.
    public func saveImage(_ image: UIImage, quality: CGFloat = 0.8) -> String? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }

        let fileName = UUID().uuidString + ".jpg"
        let fileURL = imageDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }

    /// Loads a UIImage from a local file path.
    public func loadImage(at path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }

    /// Generates a thumbnail from a local file path.
    public func thumbnail(at path: String, size: CGSize) -> UIImage? {
        guard let url = URL(string: "file://\(path)"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let maxDimension = max(size.width, size.height) * UIScreen.main.scale
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Removes a locally saved image.
    public func deleteImage(at path: String) {
        try? fileManager.removeItem(atPath: path)
    }
}
