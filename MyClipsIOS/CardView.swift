//
//  CardView.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 4/9/24.
//

import SwiftUI
import AVKit
import UIKit
import Foundation

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
    
    private func shareToInstagram(post: Post) {
        switch post.media {
        case .image(let imageURL):
            openInstagramWithImage(imageURL: imageURL)
        case .video(let videoURL):
            openInstagramWithVideo(videoURL: videoURL)
        }
    }

    private func openInstagramWithImage(imageURL: URL) {
        let tempDirectory = FileManager.default.temporaryDirectory
        let imagePath = tempDirectory.appendingPathComponent("tempImage.ig")

        do {
            try Data(contentsOf: imageURL).write(to: imagePath)
            
            if FileManager.default.fileExists(atPath: imagePath.path) {
                let instagramURL = URL(string: "instagram://library?AssetPath=\(imagePath.path)")!
                if UIApplication.shared.canOpenURL(instagramURL) {
                    UIApplication.shared.open(instagramURL, options: [:], completionHandler: nil)
                } else {
                    print("Instagram is not installed.")
                }
            } else {
                print("Image file does not exist at path: \(imagePath.path)")
            }
        } catch {
            print("Error saving the image: \(error.localizedDescription)")
        }
    }

    private func openInstagramWithVideo(videoURL: URL) {
        let tempDirectory = FileManager.default.temporaryDirectory
        let videoName = "tempVideo.ig.mp4"
        let videoPath = tempDirectory.appendingPathComponent(videoName)

        URLSession.shared.downloadTask(with: videoURL) { (tempFileURL, response, error) in
            if let error = error {
                print("Error downloading the video: \(error.localizedDescription)")
                return
            }
            guard let tempFileURL = tempFileURL else {
                print("No temp file URL found.")
                return
            }

            if FileManager.default.fileExists(atPath: videoPath.path) {
                do {
                    try FileManager.default.removeItem(at: videoPath)
                    print("Removed existing video file at path: \(videoPath.path)")
                } catch {
                    print("Error removing existing video file: \(error.localizedDescription)")
                    return
                }
            }

            do {
                try FileManager.default.copyItem(at: tempFileURL, to: videoPath)

                if FileManager.default.fileExists(atPath: videoPath.path) {
                    let instagramURL = URL(string: "instagram://library?AssetPath=\(videoPath.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
                    DispatchQueue.main.async {
                        if UIApplication.shared.canOpenURL(instagramURL) {
                            UIApplication.shared.open(instagramURL, options: [:], completionHandler: { success in
                                if success {
                                    // Eliminar archivo temporal después de compartir
                                    try? FileManager.default.removeItem(at: videoPath)
                                    print("Shared and removed video at path: \(videoPath.path)")
                                }
                            })
                        } else {
                            print("Instagram is not installed.")
                        }
                    }
                } else {
                    print("Video file does not exist at path: \(videoPath.path)")
                }
            } catch {
                print("Error saving the video: \(error.localizedDescription)")
            }
        }.resume()
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
                    .copyToPasteboard,
                    .addToReadingList,
                    .saveToCameraRoll,
                    .openInIBooks,
                    .postToFlickr,
                    .postToVimeo,
                    .postToTencentWeibo,
                    .assignToContact,
                    .print,
                    .openInIBooks,
                    .sharePlay
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
            // Descargar el video
            URLSession.shared.dataTask(with: videoURL) { data, _, error in
                if let error = error {
                    print("Error al descargar el video: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No se pudo cargar el video.")
                    return
                }

                // Crear un archivo temporal para el video
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempVideoURL = tempDirectory.appendingPathComponent("tempVideo.mp4")

                do {
                    // Escribir los datos del video en el archivo temporal
                    try data.write(to: tempVideoURL)
                    // Preparar el archivo para compartir
                    presentActivityView(with: [tempVideoURL, postText])
                } catch {
                    print("Error al guardar el video: \(error.localizedDescription)")
                }
            }.resume()
        }
    }
}
