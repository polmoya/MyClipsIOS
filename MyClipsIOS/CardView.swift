//
//  CardView.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 4/9/24.
//

import SwiftUI
import AVKit

struct FullScreenVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true  // Mostrar los controles del reproductor
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No necesitamos hacer actualizaciones específicas
    }
}


struct CardView: View {
    let post: Post
    @State private var player: AVPlayer? = nil

    var body: some View {
        VStack (alignment: .leading, spacing: 10) {
            switch post.media {
            case .image(let imageURL):
                // Usamos AsyncImage para cargar la imagen desde la URL
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView() // Muestra un indicador de carga
                            .frame(height: 250)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    case .failure:
                        // En caso de error al cargar la imagen
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
                
            case .video(let videoURL):
                if let player = player {
                    FullScreenVideoPlayer(player: player)
                        .frame(height: 250)
                        .cornerRadius(10)
                } else {
                    Color.gray.frame(height: 250)
                        .onAppear {
                            player = AVPlayer(url: videoURL)
                        }
                }
            }
            // Mostrar el título del post
            Text(post.title)
                .font(.headline)
            // Descripción del post
            Text(post.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button(action: shareToInstagram) {
                    Text("SHARE INSTAGRAM")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: shareToTwitter) {
                    Text("SHARE TWITTER")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 8) // Espacio entre la descripción y los botones
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding([.leading, .trailing, .top], 10)
    }

    private func shareToInstagram() {
        guard let url = URL(string: "instagram://app") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("Instagram no está instalado")
        }
    }

    private func shareToTwitter() {
        guard let url = URL(string: "twitter://app") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("Twitter no está instalado")
        }
    }
}
