//
//  SocialService.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import Firebase
import FirebaseFirestore
import Combine

class SocialService {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    func shareRecipe(_ recipe: Recipe, caption: String? = nil) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        let post = RecipePost(
            userId: userId,
            recipe: recipe,
            caption: caption,
            timestamp: Date(),
            likes: 0,
            comments: []
        )
        
        try await db.collection("posts").addDocument(data: post.dictionary)
    }
    
    func followUser(_ userId: String) async throws {
        guard let currentUserId = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        let batch = db.batch()
        
        // Update current user's following
        let followingRef = db.collection("users").document(currentUserId)
            .collection("following").document(userId)
        batch.setData(["timestamp": Date()], forDocument: followingRef)
        
        // Update target user's followers
        let followerRef = db.collection("users").document(userId)
            .collection("followers").document(currentUserId)
        batch.setData(["timestamp": Date()], forDocument: followerRef)
        
        try await batch.commit()
    }
    
    func likeRecipe(_ postId: String) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        let likeRef = db.collection("posts").document(postId)
            .collection("likes").document(userId)
        
        try await likeRef.setData(["timestamp": Date()])
    }
    
    func commentOnRecipe(_ postId: String, text: String) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        let comment = Comment(
            userId: userId,
            text: text,
            timestamp: Date()
        )
        
        try await db.collection("posts").document(postId)
            .collection("comments").addDocument(data: comment.dictionary)
    }
}

struct RecipePost: Codable, Identifiable {
    let id: String
    let userId: String
    let recipe: Recipe
    let caption: String?
    let timestamp: Date
    var likes: Int
    var comments: [Comment]
    
    var dictionary: [String: Any] {
        [
            "userId": userId,
            "recipe": recipe.dictionary,
            "caption": caption as Any,
            "timestamp": timestamp,
            "likes": likes
        ]
    }
}

struct Comment: Codable, Identifiable {
    let id: String
    let userId: String
    let text: String
    let timestamp: Date
    
    var dictionary: [String: Any] {
        [
            "userId": userId,
            "text": text,
            "timestamp": timestamp
        ]
    }
}