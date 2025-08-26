//
//  CrookeyApp.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//

import SwiftUI
import CoreData

@main
struct CrookeyApp: App {
    let persistenceController = PersistenceManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}