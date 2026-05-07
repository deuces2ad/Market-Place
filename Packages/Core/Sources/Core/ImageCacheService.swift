//
//  ImageCacheService.swift
//  Core
//

import UIKit

public actor ImageCacheService {

    public static let shared = ImageCacheService()

    private let cache = NSCache<NSString, UIImage>()
    private var runningTasks: [String: Task<UIImage?, Never>] = [:]

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    /// Returns a cached or freshly-downloaded image. Generates a thumbnail
    /// capped at the given point-size to limit memory usage.
    public func image(for urlString: String, thumbnailSize: CGSize? = nil) async -> UIImage? {
        let cacheKey = thumbnailSize.map { "\(urlString)_\(Int($0.width))x\(Int($0.height))" } ?? urlString
        let key = cacheKey as NSString

        // Return from cache if available
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // Deduplicate in-flight requests
        if let existingTask = runningTasks[cacheKey] {
            return await existingTask.value
        }

        let task = Task<UIImage?, Never> { [cache] in
            guard let url = URL(string: urlString) else { return nil }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                let image: UIImage?
                if let size = thumbnailSize {
                    // Generate a down-sampled thumbnail to save memory
                    image = Self.downsample(data: data, to: size)
                } else {
                    image = UIImage(data: data)
                }

                if let image {
                    cache.setObject(image, forKey: key, cost: data.count)
                }
                return image
            } catch {
                return nil
            }
        }

        runningTasks[cacheKey] = task
        let result = await task.value
        runningTasks[cacheKey] = nil
        return result
    }

    public func clearCache() {
        cache.removeAllObjects()
    }

    // MARK: - Thumbnail Generation

    private static func downsample(data: Data, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let maxDimension = max(pointSize.width, pointSize.height) * scale
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
