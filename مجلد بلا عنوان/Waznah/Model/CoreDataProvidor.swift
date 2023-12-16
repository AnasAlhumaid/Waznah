//
//  CoreDataProvidor.swift
//  Waznah
//
//  Created by Anas Hamad on 7/27/23.
//

import Foundation
import CoreData

class CoreDataProvider {
    
    static let shared = CoreDataProvider()
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {

        persistentContainer = NSPersistentContainer(name: "Waznah")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to initialize model \(error)")
            }
        }
    }
    
}
