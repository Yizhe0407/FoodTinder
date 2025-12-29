
import SwiftUI
import MapKit

struct RestaurantCardView: View {
    let restaurant: Restaurant
    let onSwipe: (SwipeDirection) -> Void
    
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var showingDetail = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Replaced AsyncImage with custom RemoteImageView
            RemoteImageView(url: restaurant.imageUrl)
                .frame(height: 240)
                .clipped() // Clip the image to the frame
            
            VStack(alignment: .leading, spacing: 12) {
                Text(restaurant.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    if let rating = restaurant.rating, rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                if let category = restaurant.category {
                    Text(category)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f 公里", restaurant.distance / 1000))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                if let phone = restaurant.phoneNumber {
                    Button(action: {
                        if let rawPhone = restaurant.rawPhoneNumber,
                           let url = URL(string: "tel://\(rawPhone)"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(phone)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .underline() // Optional: indicates it's clickable
                        }
                    }
                }
                
                Button(action: { showingDetail = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.system(size: 16))
                        Text("詳細資訊 & 導航")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Color(UIColor.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.primary)
                    .cornerRadius(12)
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .overlay(
            ZStack {
                if offset.width > 0 {
                    Text("LIKE")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundColor(.green)
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green, lineWidth: 4)
                        )
                        .rotationEffect(.degrees(-15))
                        .opacity(Double(offset.width / 150))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(40)
                }
                
                if offset.width < 0 {
                    Text("NOPE")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundColor(.red)
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 4)
                        )
                        .rotationEffect(.degrees(15))
                        .opacity(Double(abs(offset.width) / 150))
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .padding(40)
                }
            }
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 25)
                }
                .onEnded { gesture in
                    if abs(gesture.translation.width) > 150 {
                        let direction: SwipeDirection = gesture.translation.width > 0 ? .right : .left
                        
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            offset = CGSize(
                                width: gesture.translation.width > 0 ? 500 : -500,
                                height: gesture.translation.height
                            )
                            rotation = gesture.translation.width > 0 ? 20 : -20
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwipe(direction)
                        }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
        )
        .sheet(isPresented: $showingDetail) {
            RestaurantDetailView(restaurant: restaurant)
        }
    }
}

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @Environment(\.dismiss) var dismiss
    @State private var detailMapRegion: MKCoordinateRegion
    
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        _detailMapRegion = State(initialValue: MKCoordinateRegion(
            center: restaurant.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Map(coordinateRegion: $detailMapRegion, annotationItems: [restaurant]) { place in
                    MapPin(coordinate: place.coordinate, tint: .primary)
                }
                .frame(height: 340)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(restaurant.name)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        if let rating = restaurant.rating, rating > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    if let category = restaurant.category {
                        Text(category)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f 公里", restaurant.distance / 1000))
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    if let phone = restaurant.phoneNumber {
                        Button(action: {
                            if let rawPhone = restaurant.rawPhoneNumber,
                               let url = URL(string: "tel://\(rawPhone)"),
                               UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(phone)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .underline()
                            }
                        }
                    }
                    
                    Button("在 Apple Maps 中開啟") {
                        restaurant.openInMaps()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.primary)
                    .cornerRadius(16)
                    .padding(.top, 8)
                }
                .padding(24)
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("餐廳詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.primary) // Changed to .primary
                    .fontWeight(.medium)
                }
            }
        }
    }
}

enum SwipeDirection {
    case left, right
}
