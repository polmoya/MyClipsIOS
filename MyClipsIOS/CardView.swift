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
                Button(action: {
                    shareToInstagram(post: post)
                }) {
                    Text("SHARE INSTAGRAM")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    shareToTwitter(post: post)
                }) {
                    Text("SHARE\nTWITTER")
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
    
    private func presentDocumentController(_ documentController: UIDocumentInteractionController) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            documentController.presentOpenInMenu(from: .zero, in: keyWindow, animated: true)
        } else {
            print("No se pudo encontrar la ventana principal")
        }
    }


    // Función para compartir en Instagram
        private func shareToInstagram(post: Post) {
            guard let instagramURL = URL(string: "instagram://app") else { return }
            
            if UIApplication.shared.canOpenURL(instagramURL) {
                switch post.media {
                case .image(let imageURL):
                    if let imageData = try? Data(contentsOf: imageURL),
                       let image = UIImage(data: imageData) {
                        saveAndShareImageToInstagram(image: image)
                    }
                case .video(let videoURL):
                    shareVideoToInstagram(videoURL: videoURL)
                }
            } else {
                print("Instagram no está instalado")
            }
        }
        
        private func saveAndShareImageToInstagram(image: UIImage) {
            let tempDirectory = FileManager.default.temporaryDirectory
            let imagePath = tempDirectory.appendingPathComponent("tempImage.ig")

            do {
                try image.jpegData(compressionQuality: 1.0)?.write(to: imagePath)

                let documentController = UIDocumentInteractionController(url: imagePath)
                documentController.uti = "com.instagram.exclusivegram"
                presentDocumentController(documentController)
            } catch {
                print("Error al guardar la imagen: \(error.localizedDescription)")
            }
        }
        
        private func shareVideoToInstagram(videoURL: URL) {
            let tempDirectory = FileManager.default.temporaryDirectory
            let videoPath = tempDirectory.appendingPathComponent("tempVideo.ig.mp4")

            do {
                try FileManager.default.copyItem(at: videoURL, to: videoPath)

                let documentController = UIDocumentInteractionController(url: videoPath)
                documentController.uti = "com.instagram.exclusivegram.video"
                presentDocumentController(documentController)
            } catch {
                print("Error al guardar el video: \(error.localizedDescription)")
            }
        }

    
    

    private func shareToTwitter(post: Post) {
        guard let url = URL(string: "twitter://app") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("Twitter no está instalado")
        }
    }
}
