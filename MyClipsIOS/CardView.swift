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
    @Environment(\.colorScheme) var colorScheme // Detecta el tema actual (light o dark)
    
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
                .foregroundColor(Color.white)
            // Descripción del post
            Text(post.description)
                .font(.subheadline)
                .foregroundColor(Color.white)
            
            HStack(spacing: 20) {
                Button(action: {
                    shareToInstagram(post: post)
                }) {
                    Text("SHARE INSTAGRAM")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color("cardBckgrnd"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("mainColor"), lineWidth: 2)
                            )
                }
                
                Button(action: {
                    shareToTwitter(post: post)
                }) {
                    Text("SHARE\nX")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color("cardBckgrnd"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("mainColor"), lineWidth: 2)
                            )
                }
                Button(action: {
                    downloadContent(post: post)
                }) {
                    Image(systemName: "arrow.down.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .background(Color("cardBckgrnd"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("mainColor"), lineWidth: 2)
                            )
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.1)
            }
            .padding(.top, 8) // Espacio entre la descripción y los botones
        }
        .padding()
        .background(Color("cardBckgrnd"))
        .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 2)
            )
        .shadow(radius: 5)
        .padding([.leading, .trailing, .top], 10)
    }
    
    private func downloadContent(post: Post) {
        switch post.media {
        case .image(let imageURL):
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                if let error = error {
                    print("Error al descargar la imagen: \(error.localizedDescription)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    print("Imagen guardada")
                } else {
                    print("No se pudo descargar la imagen.")
                }
            }.resume()
            
        case .video(let videoURL):
            let downloadTask = URLSession.shared.downloadTask(with: videoURL) { location, response, error in
                if let error = error {
                    print("Error al descargar el video: \(error.localizedDescription)")
                    return
                }
                
                guard let location = location else {
                    print("No se pudo encontrar la ubicación temporal del video.")
                    return
                }
                
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(response?.suggestedFilename ?? videoURL.lastPathComponent)
                do {
                    try FileManager.default.moveItem(at: location, to: destination)
                    UISaveVideoAtPathToSavedPhotosAlbum(destination.path, nil, nil, nil)
                    print("Video guardado")
                } catch {
                    print("Error al mover el video: \(error)")
                }
            }
            downloadTask.resume()
        }
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

    // Función para compartir en Twitter
    private func shareToTwitter(post: Post) {
        // Obtener la escena activa de la ventana
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = keyWindow.rootViewController else {
            print("No se pudo encontrar la ventana principal.")
            return
        }

        // Selección de media: imagen o video
        switch post.media {
        case .image(let imageURL):
            // Cargar la imagen de forma asíncrona
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                if let error = error {
                    print("Error al descargar la imagen: \(error)")
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    print("No se pudo cargar la imagen.")
                    return
                }
                
                // Volver al hilo principal para actualizar la interfaz de usuario
                DispatchQueue.main.async {
                    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                    rootViewController.present(activityVC, animated: true, completion: nil)
                }
            }.resume()

        case .video(let videoURL):
            // No necesitamos descargar el video, solo compartir el URL
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
                rootViewController.present(activityVC, animated: true, completion: nil)
            }
        }
    }


}
