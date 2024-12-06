import Foundation

protocol RecipeServiceProtocol {
    func fetchRandomRecipe() async throws -> Recipe
    func searchRecipes(query: String) async throws -> [Recipe]
    func getRecipeDetails(id: Int) async throws -> Recipe
}

class RecipeService: RecipeServiceProtocol {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
    }
    
    func fetchRandomRecipe() async throws -> Recipe {
        let endpoint = "/recipes/random?number=1"
        let response: RecipeResponse = try await networkManager.fetch(endpoint)
        return response.recipes[0]
    }
    
    func searchRecipes(query: String) async throws -> [Recipe] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoint = "/recipes/complexSearch?query=\(encodedQuery)&number=20"
        let response: RecipeSearchResponse = try await networkManager.fetch(endpoint)
        return response.results
    }
    
    func getRecipeDetails(id: Int) async throws -> Recipe {
        let endpoint = "/recipes/\(id)/information"
        return try await networkManager.fetch(endpoint)
    }
}