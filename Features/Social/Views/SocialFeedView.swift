//
//  SocialFeedView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct SocialFeedView: View {
    @StateObject private var viewModel = SocialFeedViewModel()
    @State private var showingNewPost = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.Layout.spacing) {
                    ForEach(viewModel.posts) { post in
                        RecipePostCard(post: post)
                            .onAppear {
                                if post == viewModel.posts.last {
                                    Task {
                                        await viewModel.loadMorePosts()
                                    }
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Recipe Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewPost = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewPost) {
                NewPostView(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.refreshPosts()
            }
        }
    }
}

struct RecipePostCard: View {
    let post: RecipePost
    @StateObject private var viewModel: RecipePostViewModel
    
    init(post: RecipePost) {
        self.post = post
        self._viewModel = StateObject(wrappedValue: RecipePostViewModel(post: post))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacing) {
            // User Header
            HStack {
                AsyncImage(url: URL(string: viewModel.userProfileImage)) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(viewModel.userName)
                        .font(AppTheme.Fonts.headline)
                    Text(post.timestamp.formatted(.relative))
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: viewModel.showOptions) {
                    Image(systemName: "ellipsis")
                }
            }
            
            // Recipe Image
            AsyncImage(url: URL(string: post.recipe.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(height: 300)
            .clipped()
            .cornerRadius(AppTheme.Layout.cornerRadius)
            
            // Caption
            if let caption = post.caption {
                Text(caption)
                    .font(AppTheme.Fonts.body)
            }
            
            // Interaction Buttons
            HStack {
                Button(action: viewModel.toggleLike) {
                    HStack {
                        Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isLiked ? .red : .primary)
                        Text("\(post.likes)")
                    }
                }
                
                Spacer()
                
                Button(action: viewModel.showComments) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments.count)")
                    }
                }
                
                Spacer()
                
                Button(action: viewModel.shareRecipe) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .font(AppTheme.Fonts.caption)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.Layout.cornerRadius)
        .shadow(radius: 2)
    }
}