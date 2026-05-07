//
//  Formatters.swift
//  Core
//

import Foundation
import CoreLocation

public enum Formatters {

    // MARK: - Distance

    public static func formattedDistance(_ meters: CLLocationDistance?) -> String {
        guard let meters else { return "—" }
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    // MARK: - Price

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }()

    public static func formattedPrice(_ price: Double) -> String {
        priceFormatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }

    // MARK: - Date / Time

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private static let listingDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d 'at' h:mm a"
        return f
    }()

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f
    }()

    public static func relativeTime(from date: Date) -> String {
        relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    public static func listingDate(_ date: Date) -> String {
        listingDateFormatter.string(from: date)
    }

    public static func fullDate(_ date: Date) -> String {
        fullDateFormatter.string(from: date)
    }
}
