
import SwiftUI

struct RemoteImageView: View {
    let url: URL?
    
    @State private var image: Image?
    @State private var isLoading = false
    
    var body: some View {
        Color(UIColor.secondarySystemBackground)
            .overlay(
                ZStack {
                    if let image = image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if isLoading {
                        ProgressView()
                    } else {
                        // Improved placeholder
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "fork.knife")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                    }
                }
            )
            .clipped()
            .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        guard let url = url else { return }
        
        guard image == nil else { return }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    return
                }
                
                if let data = data, let uiImage = UIImage(data: data) {
                    self.image = Image(uiImage: uiImage)
                }
            }
        }.resume()
    }
}
