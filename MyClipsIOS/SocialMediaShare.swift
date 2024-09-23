//
//  SocialMediaShare.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 23/9/24.
//

import Foundation
import Photos
import UIKit
import SwiftUI


class SocialMediaSharing: ObservableObject {
    func shareToInstagram(post: Post) {
        switch post.media {
        case .image(let imageURL):
            openInstagramWithImage(imageURL: imageURL, postId: post.id.uuidString)
        case .video(let videoURL):
            openInstagramWithVideo(videoURL: videoURL, postId: post.id.uuidString)
        }
    }

    private func openInstagramWithImage(imageURL: URL, postId: String) {
        // Descargar y guardar la imagen en el álbum de fotos
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let error = error {
                print("Error al downloading image: \(error.localizedDescription)")
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
                            print("Image downloaded successfully!")
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

    private func openInstagramWithVideo(videoURL: URL, postId: String) {
        let videoName = postId + ".mp4"
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoPath = documentsDirectory.appendingPathComponent(videoName)
        URLSession.shared.downloadTask(with: videoURL) { (tempFileURL, response, error) in
            if let error = error {
                print("Error downloading the video: \(error.localizedDescription)")
                return
            }
            guard let tempFileURL = tempFileURL else {
                print("No temp file URL found.")
                return
            }
            do {
                // Remove any file that may already exist at this path
                if fileManager.fileExists(atPath: videoPath.path) {
                    try fileManager.removeItem(at: videoPath)
                }
                // Move the downloaded file to the permanent location
                try fileManager.copyItem(at: tempFileURL, to: videoPath)
                // Save the video to Photos library and track local identifier
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        PHPhotoLibrary.shared().performChanges({
                            let creationRequest = PHAssetCreationRequest.forAsset()
                            creationRequest.addResource(with: .video, fileURL: videoPath, options: nil)
                            // Capture the local identifier of the saved video
                            let localIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
                            
                            DispatchQueue.main.async {
                                // Wait a moment to ensure the video is available in the Photos library
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    if let localIdentifier = localIdentifier {
                                        let instagramURL = URL(string: "instagram://library?LocalIdentifier=\(localIdentifier)")!
                                        if UIApplication.shared.canOpenURL(instagramURL) {
                                            UIApplication.shared.open(instagramURL, options: [:], completionHandler: { success in
                                                if success {
                                                    print("Successfully shared the video!")
                                                } else {
                                                    print("Failed to open Instagram.")
                                                }
                                            })
                                        } else {
                                            print("Instagram is not installed.")
                                        }
                                    } else {
                                        print("Failed to retrieve localIdentifier for the video.")
                                    }
                                }
                            }
                        }) { success, error in
                            if !success {
                                print("Failed to save the video: \(String(describing: error))")
                            }
                        }
                    } else {
                        print("Photo library access denied.")
                    }
                }
            } catch {
                print("Error handling the video file: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func shareToTwitter(post: Post, additionalText: String = "") {
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
