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
    @StateObject private var viewModel = DownloadViewModel()
    
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
                            .frame(maxWidth: UIScreen.main.bounds.width - 20, maxHeight: 250)
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
                    viewModel.downloadContent(post: post)
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
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text("Download Status"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
                }
                .confirmationDialog(viewModel.alertMessage, isPresented: $viewModel.showConfirmation, titleVisibility: .visible) {
                    Button("Download Again") {
                        viewModel.confirmDownload(post: post)
                    }
                    Button("Cancel", role: .cancel) { }
                }
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
    
    private func presentDocumentController(_ documentController: UIDocumentInteractionController) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let rootViewController = keyWindow.rootViewController else {
                print("No se pudo encontrar la ventana principal")
                return
            }

            let rect = CGRect(x: keyWindow.frame.midX, y: keyWindow.frame.midY, width: 0, height: 0)
            documentController.presentOpenInMenu(from: rect, in: rootViewController.view, animated: true)
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
            
            if FileManager.default.fileExists(atPath: imagePath.path) {
                let documentController = UIDocumentInteractionController(url: imagePath)
                documentController.uti = "com.instagram.exclusivegram"
                presentDocumentController(documentController)
            } else {
                print("Image file does not exist at path: \(imagePath.path)")
            }
        } catch {
            print("Error al guardar la imagen: \(error.localizedDescription)")
        }
    }

    private func shareVideoToInstagram(videoURL: URL) {
        let tempDirectory = FileManager.default.temporaryDirectory
        let videoPath = tempDirectory.appendingPathComponent("tempVideo.ig.mp4")

        do {
            try FileManager.default.copyItem(at: videoURL, to: videoPath)
            
            if FileManager.default.fileExists(atPath: videoPath.path) {
                let documentController = UIDocumentInteractionController(url: videoPath)
                documentController.uti = "com.instagram.exclusivegram.video"
                presentDocumentController(documentController)
            } else {
                print("Video file does not exist at path: \(videoPath.path)")
            }
        } catch {
            print("Error al guardar el video: \(error.localizedDescription)")
        }
    }


    private func shareToTwitter(post: Post) {
        // Obtener la escena activa de la ventana
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = keyWindow.rootViewController else {
            print("No se pudo encontrar la ventana principal.")
            return
        }

        // Texto adicional para el post
        let postText = "Check out my clip from #bakuriani2025"

        // Función para presentar el UIActivityViewController
        func presentActivityView(with items: [Any]) {
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                // Excluir otras actividades
                activityVC.excludedActivityTypes = [
                    .postToFacebook,
                    .postToWeibo,
                    .message,
                    .mail,
                    .airDrop,
                    .copyToPasteboard,       // This excludes copying to the pasteboard (Notes can be a part of this)
                    .addToReadingList,       // Excludes adding to Reading List (sometimes associated with Notes)
                    .saveToCameraRoll,       // If saving to camera roll is not desired
                    .openInIBooks,           // Excludes opening in iBooks
                    .postToFlickr,           // Excludes posting to Flickr
                    .postToVimeo,            // Excludes posting to Vimeo
                    .postToTencentWeibo,     // Excludes posting to Tencent Weibo
                    .assignToContact,
                    .print,
                ]
                rootViewController.present(activityVC, animated: true, completion: nil)
            }
        }

        // Selección de media: imagen o video
        switch post.media {
        case .image(let imageURL):
            // Cargar la imagen de forma asíncrona
            URLSession.shared.dataTask(with: imageURL) { data, _, error in
                if let error = error {
                    print("Error al descargar la imagen: \(error)")
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    print("No se pudo cargar la imagen.")
                    return
                }

                presentActivityView(with: [image, postText])
            }.resume()

        case .video(let videoURL):
            presentActivityView(with: [videoURL, postText])
        }
    }

}
