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
import Photos


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
                .id(post.id)
                
            case .video(let videoURL):
                if let player = player {
                    FullScreenVideoPlayer(player: player)
                        .frame(height: 250)
                        .cornerRadius(10)
                        .id(post.id)
                } else {
                    Color.gray.frame(height: 250)
                        .onAppear {
                            player = AVPlayer(url: videoURL)
                        }
                        .id(post.id)
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
        // Descargar y guardar la imagen en el álbum de fotos
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let error = error {
                print("Error al descargar la imagen: \(error.localizedDescription)")
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                print("No se pudo obtener la imagen desde la URL.")
                return
            }
            
            // Solicitar acceso al álbum de fotos
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Guardar la imagen en el álbum de fotos
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, error in
                        if success {
                            print("Imagen guardada en el álbum de fotos.")
                            
                            // Abrir Instagram y compartir la imagen
                            DispatchQueue.main.async {
                                if let instagramURL = URL(string: "instagram://library?AssetPath=\(imageURL.path)") {
                                    if UIApplication.shared.canOpenURL(instagramURL) {
                                        UIApplication.shared.open(instagramURL, options: [:], completionHandler: nil)
                                    } else {
                                        print("Instagram no está instalado.")
                                    }
                                }
                            }
                        } else if let error = error {
                            print("Error al guardar la imagen: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("Acceso al álbum de fotos denegado.")
                }
            }
        }.resume()
    }

    private func openInstagramWithVideo(videoURL: URL) {
        // Descargar y guardar el video en el álbum de fotos
        URLSession.shared.downloadTask(with: videoURL) { tempFileURL, response, error in
            if let error = error {
                print("Error al descargar el video: \(error.localizedDescription)")
                return
            }
            guard let tempFileURL = tempFileURL else {
                print("No se encontró la URL del archivo temporal.")
                return
            }
            
            // Solicitar acceso al álbum de fotos
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Guardar el video en el álbum de fotos
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempFileURL)
                    }) { success, error in
                        if success {
                            print("Video guardado en el álbum de fotos.")
                            
                            // Abrir Instagram y compartir el video
                            DispatchQueue.main.async {
                                if let instagramURL = URL(string: "instagram://library?AssetPath=\(videoURL.path)") {
                                    if UIApplication.shared.canOpenURL(instagramURL) {
                                        UIApplication.shared.open(instagramURL, options: [:], completionHandler: nil)
                                    } else {
                                        print("Instagram no está instalado.")
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        else if let error = error {
                            print("Error al guardar el video: \(error.localizedDescription)")
                        }
                    }
                }  
                else {
                    print("Acceso al álbum de fotos denegado.")
                }
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
