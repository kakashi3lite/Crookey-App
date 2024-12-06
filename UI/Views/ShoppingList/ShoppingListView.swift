//
//  ShoppingListView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct ShoppingListView: View {
    @StateObject private var viewModel = ShoppingListViewModel()
    @State private var showingAddItem = false
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.items.isEmpty {
                    EmptyShoppingListView()
                } else {
                    ForEach(viewModel.groupedItems.keys.sorted(), id: \.self) { category in
                        Section(header: Text(category)) {
                            ForEach(viewModel.groupedItems[category] ?? [], id: \.id) { item in
                                ShoppingListItemRow(item: item) { id in
                                    viewModel.toggleItem(id)
                                }
                            }
                            .onDelete { indexSet in
                                viewModel.deleteItems(at: indexSet, category: category)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                if !viewModel.items.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddShoppingItemView(viewModel: viewModel)
            }
        }
    }
}

struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let onToggle: (Int64) -> Void
    
    var body: some View {
        HStack {
            Button(action: { onToggle(item.id) }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isChecked ? AppTheme.accent : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(AppTheme.Fonts.body)
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .gray : AppTheme.text)
                
                Text("\(String(format: "%.1f", item.amount)) \(item.unit)")
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(item.dateAdded.formatted(.relative))
                .font(AppTheme.Fonts.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyShoppingListView: View {
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacing * 2) {
            Image(systemName: "cart")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.accent)
            
            Text("Your shopping list is empty")
                .font(AppTheme.Fonts.headline)
            
            Text("Add items manually or from recipes")
                .font(AppTheme.Fonts.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}