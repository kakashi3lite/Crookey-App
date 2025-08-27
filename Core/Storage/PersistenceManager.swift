//
//  PersistenceManager.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import CoreData
import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Crookey")
        container.loadPersistentStores { description, error in
            if let error = error {
                Logger.shared.logError("Core Data store load failed", error: error)
                // Attempt to recover by removing the store and creating a new one
                self.handleCoreDataRecovery(container: container, error: error)
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            Logger.shared.logInfo("Core Data context saved successfully")
        } catch {
            Logger.shared.logError("Core Data save failed", error: error)
            // Attempt recovery
            handleSaveError(error)
        }
    }
    
    private func handleCoreDataRecovery(container: NSPersistentContainer, error: Error) {
        let coordinator = container.persistentStoreCoordinator
        
        // Attempt to remove corrupted store
        if let storeURL = coordinator.persistentStores.first?.url {
            do {
                try coordinator.destroyPersistentStore(at: storeURL, type: .sqlite, options: nil)
                try FileManager.default.removeItem(at: storeURL)
                Logger.shared.logInfo("Corrupted store removed, attempting to recreate")
                
                // Try to recreate the store
                container.loadPersistentStores { _, error in
                    if let error = error {
                        Logger.shared.logError("Failed to recreate Core Data store", error: error)
                    }
                }
            } catch {
                Logger.shared.logError("Failed to recover Core Data store", error: error)
            }
        }
    }
    
    private func handleSaveError(_ error: Error) {
        // Rollback changes and attempt merge
        context.rollback()
        Logger.shared.logWarning("Context rolled back due to save error")
        
        // Notify observers of the error
        NotificationCenter.default.post(
            name: .coreDataSaveFailed,
            object: nil,
            userInfo: ["error": error]
        )
    }
    
    // MARK: - Recipe Operations
    
    func saveRecipe(_ recipe: Recipe) {
        let savedRecipe = SavedRecipe(context: context)
        savedRecipe.id = Int64(recipe.id)
        savedRecipe.title = recipe.title
        savedRecipe.image = recipe.image
        savedRecipe.summary = recipe.summary
        savedRecipe.instructions = recipe.instructions
        savedRecipe.readyInMinutes = Int16(recipe.readyInMinutes)
        savedRecipe.servings = Int16(recipe.servings)
        savedRecipe.dateAdded = Date()
        
        if let ingredients = recipe.ingredients {
            for ingredient in ingredients {
                let savedIngredient = SavedIngredient(context: context)
                savedIngredient.id = Int64(ingredient.id)
                savedIngredient.name = ingredient.name
                savedIngredient.amount = ingredient.amount
                savedIngredient.unit = ingredient.unit
                savedIngredient.image = ingredient.image
                savedIngredient.recipe = savedRecipe
            }
        }
        
        saveContext()
    }
    
    func fetchSavedRecipes() -> [Recipe] {
        let request: NSFetchRequest<SavedRecipe> = SavedRecipe.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        
        do {
            let savedRecipes = try context.fetch(request)
            return savedRecipes.map { saved in
                Recipe(
                    id: Int(saved.id),
                    title: saved.title ?? "",
                    readyInMinutes: Int(saved.readyInMinutes),
                    servings: Int(saved.servings),
                    image: saved.image ?? "",
                    summary: saved.summary ?? "",
                    instructions: saved.instructions,
                    healthScore: nil,
                    isFavorite: true
                )
            }
        } catch {
            print("Error fetching saved recipes: \(error)")
            return []
        }
    }
    
    // MARK: - Shopping List Operations
    
    func addToShoppingList(_ ingredients: [Ingredient]) {
        for ingredient in ingredients {
            let item = ShoppingListItem(context: context)
            item.id = Int64(ingredient.id)
            item.name = ingredient.name
            item.amount = ingredient.amount
            item.unit = ingredient.unit
            item.dateAdded = Date()
            item.isChecked = false
        }
        
        saveContext()
    }
    
    func toggleShoppingListItem(_ id: Int64) {
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            let items = try context.fetch(request)
            if let item = items.first {
                item.isChecked.toggle()
                saveContext()
            }
        } catch {
            print("Error toggling shopping list item: \(error)")
        }
    }
    
    func fetchShoppingList() -> [ShoppingListItem] {
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "isChecked", ascending: true),
            NSSortDescriptor(key: "dateAdded", ascending: false)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching shopping list: \(error)")
            return []
        }
    }
}