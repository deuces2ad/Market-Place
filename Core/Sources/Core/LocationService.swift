//
//  LocationService.swift
//  Core
//

import CoreLocation
import Combine
import Foundation

public protocol LocationServiceProtocol: AnyObject {
    var currentLocation: CLLocation? { get }
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestPermission()
    func startUpdating()
    func stopUpdating()
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance?
}

public final class LocationService: NSObject, LocationServiceProtocol {

    private let locationManager = CLLocationManager()

    private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private let authorizationSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)

    public var currentLocation: CLLocation? { locationSubject.value }

    public var locationPublisher: AnyPublisher<CLLocation?, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    public var authorizationStatus: CLAuthorizationStatus {
        authorizationSubject.value
    }

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
    }

    public func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    public func startUpdating() {
        locationManager.startUpdatingLocation()
    }

    public func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }

    public func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationSubject.send(location)
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationSubject.send(manager.authorizationStatus)

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        default:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
