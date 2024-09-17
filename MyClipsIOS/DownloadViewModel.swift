//
//  DownloadViewModel.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 16/9/24.
//

import SwiftUI
import Combine

class DownloadViewModel: ObservableObject {
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showConfirmation = false
    @Published var shouldDownload = false
    
    private var fileManager = FileManager.default

    func downloadContent(post: Post) {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        switch post.media {
        case .image(let imageURL):
            let imageFileName = imageURL.lastPathComponent
            let imageFilePath = documentDirectory.appendingPathComponent(imageFileName).path

            if fileManager.fileExists(atPath: imageFilePath) {
                // Ask the user for confirmation if the file already exists
                alertMessage = "This image has already been downloaded. Do you want to download it again?"
                showConfirmation = true
            } else {
                // Download if the file doesn't exist
                downloadImage(from: imageURL, filePath: imageFilePath)
            }

        case .video(let videoURL):
            let videoFileName = videoURL.lastPathComponent
            let videoFilePath = documentDirectory.appendingPathComponent(videoFileName).path

            if fileManager.fileExists(atPath: videoFilePath) {
                // Ask the user for confirmation if the file already exists
                alertMessage = "This video has already been downloaded. Do you want to download it again?"
                showConfirmation = true
            } else {
                // Download if the file doesn't exist
                downloadVideo(from: videoURL, filePath: videoFilePath)
            }
        }
    }

    func confirmDownload(post: Post) {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        switch post.media {
        case .image(let imageURL):
            let imageFileName = imageURL.lastPathComponent
            let imageFilePath = documentDirectory.appendingPathComponent(imageFileName).path
            downloadImage(from: imageURL, filePath: imageFilePath)
            
        case .video(let videoURL):
            let videoFileName = videoURL.lastPathComponent
            let videoFilePath = documentDirectory.appendingPathComponent(videoFileName).path
            downloadVideo(from: videoURL, filePath: videoFilePath)
        }
    }

    private func downloadImage(from url: URL, filePath: String) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                return
            }

            if let data = data, let image = UIImage(data: data) {
                do {
                    try data.write(to: URL(fileURLWithPath: filePath))
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    DispatchQueue.main.async {
                        self.alertMessage = "Image downloaded successfully!"
                        self.showAlert = true
                    }
                } catch {
                    print("Error saving image: \(error.localizedDescription)")
                }
            } else {
                print("Failed to load image data.")
            }
        }.resume()
    }

    private func downloadVideo(from url: URL, filePath: String) {
        URLSession.shared.downloadTask(with: url) { location, response, error in
            if let error = error {
                print("Error downloading video: \(error.localizedDescription)")
                return
            }

            guard let location = location else {
                print("Failed to locate temporary video file.")
                return
            }

            // Generate a unique file name by appending a UUID or timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let uniqueFileName = "\(timestamp)-" + url.lastPathComponent
            let uniqueFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(uniqueFileName)

            do {
                // Move the downloaded file to the unique path
                try FileManager.default.moveItem(at: location, to: uniqueFilePath)
                UISaveVideoAtPathToSavedPhotosAlbum(uniqueFilePath.path, nil, nil, nil)
                
                DispatchQueue.main.async {
                    self.alertMessage = "Video downloaded successfully!"
                    self.showAlert = true
                }
            } catch {
                print("Error saving video: \(error.localizedDescription)")
            }
        }.resume()
    }
}
