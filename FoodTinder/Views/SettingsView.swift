import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: RestaurantViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // 類別選擇
                Section {
                    Picker("餐廳類別", selection: $viewModel.selectedCategory) {
                        ForEach(FoodCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .onChange(of: viewModel.selectedCategory) { _ in
                        viewModel.requestLocationAndSearch()
                    }
                } header: {
                    Text("搜尋類別")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
                
                // 排序方式
                Section {
                    Picker("排序方式", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .onChange(of: viewModel.sortOption) { _ in
                        viewModel.applyFiltersAndSort()
                    }
                } header: {
                    Text("排序設定")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
                
                // 智能過濾
                Section {
                    Toggle("只顯示營業中", isOn: $viewModel.showOnlyOpen)
                        .onChange(of: viewModel.showOnlyOpen) { _ in
                            viewModel.requestLocationAndSearch(resetViewed: false)
                        }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最低評分")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f★", viewModel.minimumRating))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $viewModel.minimumRating,
                            in: 0...5,
                            step: 0.5
                        )
                        .tint(.primary)
                        .onChange(of: viewModel.minimumRating) { _ in
                            viewModel.applyFiltersAndSort()
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("智能過濾")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
                
                // 搜尋範圍
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("搜尋半徑")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f 公里", viewModel.searchRadius / 1000))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $viewModel.searchRadius,
                            in: 500...40000,
                            step: 500
                        )
                        .tint(.primary)
                        .onChange(of: viewModel.searchRadius) { _ in
                            viewModel.requestLocationAndSearch(resetViewed: false)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("搜尋範圍")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
                
                // 關於
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FoodTinder")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("版本 1.0")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text("解決選擇困難症的美食決策助手")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("關於")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                }
            }
        }
    }
}
