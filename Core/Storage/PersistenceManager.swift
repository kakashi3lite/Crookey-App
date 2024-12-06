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
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
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