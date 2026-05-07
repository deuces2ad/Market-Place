//
//  Market_PlaceApp.swift
//  Market Place
//
//

import SwiftUI
import Models
import Networking
import Core

@main
struct Market_PlaceApp: App {

    @StateObject
    private var container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(ViewModelFactory(container: container))
        }
    }
}
