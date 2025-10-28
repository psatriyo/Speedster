//
//  SpeedsterApp.swift
//  Speedster
//
//  Created by Prayudi Satriyo on 29/10/25.
//

import SwiftUI
import CoreData

@main
struct SpeedsterApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
