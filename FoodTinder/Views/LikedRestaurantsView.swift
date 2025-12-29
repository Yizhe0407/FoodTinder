
import SwiftUI

struct LikedRestaurantsView: View {
    @ObservedObject var viewModel: RestaurantViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.likedRestaurants.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("還沒有收藏的餐廳")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("右滑喜歡的餐廳，它們就會出現在這裡！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(viewModel.likedRestaurants) { restaurant in
                            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                                LikedRestaurantRow(restaurant: restaurant)
                            }
                        }
                        .onDelete(perform: deleteRestaurant)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("收藏清單")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func deleteRestaurant(at offsets: IndexSet) {
        offsets.forEach { index in
            let restaurant = viewModel.likedRestaurants[index]
            viewModel.removeLikedRestaurant(restaurant)
        }
    }
}

struct LikedRestaurantRow: View {
    let restaurant: Restaurant
    
    var body: some View {
        HStack(spacing: 12) {
            // Small thumbnail
            RemoteImageView(url: restaurant.imageUrl)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let rating = restaurant.rating, rating > 0 {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    }
                    
                    if let category = restaurant.category {
                        Text("• \(category)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
