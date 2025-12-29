import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RestaurantViewModel()
    @State private var showingSettings = false
    @State private var showingFavorites = false
    @AppStorage("swipeCount") private var swipeCount = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Use a softer background color
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 頂部標題區域
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FoodTinder")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("發現附近美食")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: { showingFavorites = true }) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            
                            Button(action: { showingSettings.toggle() }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // 卡片堆疊區域
                    ZStack {
                        if viewModel.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                
                                Text("尋找附近餐廳...")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                        } else if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                Text("發生錯誤")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("重試") {
                                    viewModel.requestLocationAndSearch()
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(UIColor.systemBackground))
                                .frame(width: 140, height: 44)
                                .background(Color.primary)
                                .cornerRadius(22)
                                .padding(.top, 8)
                            }
                        } else if viewModel.restaurants.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "location.slash.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("附近沒有找到餐廳")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text("請確認定位權限已開啟，或嘗試放寬搜尋設定。")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("重新搜尋") {
                                    viewModel.requestLocationAndSearch()
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(UIColor.systemBackground))
                                .frame(width: 140, height: 44)
                                .background(Color.primary)
                                .cornerRadius(22)
                                .padding(.top, 8)
                            }
                        } else if viewModel.currentIndex >= viewModel.restaurants.count {
                            VStack(spacing: 20) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                
                                Text("已經看過所有餐廳了")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text("您可以嘗試放寬搜尋範圍或切換類別。")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("載入更多餐廳") {
                                    viewModel.loadMoreRestaurants()
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(UIColor.systemBackground))
                                .frame(width: 140, height: 44)
                                .background(Color.secondary)
                                .cornerRadius(22)
                                
                                Button("重新搜尋") {
                                    viewModel.requestLocationAndSearch()
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(UIColor.systemBackground))
                                .frame(width: 140, height: 44)
                                .background(Color.primary)
                                .cornerRadius(22)
                                .padding(.top, 8)
                            }
                        } else {
                            ForEach(viewModel.restaurants.indices.reversed(), id: \.self) { index in
                                // Only render the top card for a minimalist look
                                if index == viewModel.currentIndex {
                                    createCardView(for: index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32) // Apply padding to the container
                    .frame(maxWidth: .infinity) // Add stable frame of reference
                    
                    if !viewModel.restaurants.isEmpty && swipeCount < 20 && viewModel.currentIndex < viewModel.restaurants.count {
                        HStack(spacing: 8) {
                            Text("← 左滑跳過")
                            Text("・")
                            Text("右滑收藏 →")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                        .transition(.opacity)
                    }
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFavorites) {
                LikedRestaurantsView(viewModel: viewModel)
            }
            .onAppear {
                if viewModel.restaurants.isEmpty {
                    viewModel.requestLocationAndSearch()
                }
            }
        }
    }
    
    // Helper function to create card view with stacking modifiers
    @ViewBuilder
    private func createCardView(for index: Int) -> some View {
        RestaurantCardView(
            restaurant: viewModel.restaurants[index],
            onSwipe: { direction in
                viewModel.handleSwipe(direction: direction)
                swipeCount += 1
            }
        )
        // Padding is now applied to the parent container
    }
}
