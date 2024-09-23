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

struct ButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
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
}

extension View {
    func buttonStyle() -> some View {
        self.modifier(ButtonStyleModifier())
    }
}



struct CardView: View {
    let post: Post
    @State private var player: AVPlayer? = nil
    @StateObject private var viewModel = DownloadViewModel()
    @StateObject private var socialMediaSharing = SocialMediaSharing()

    
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
            Text(post.title)    //Post Title
                .font(.headline)
                .foregroundColor(Color.white)
            Text(post.description)  //Post Description
                .font(.subheadline)
                .foregroundColor(Color.white)
            HStack(spacing: 20) {
                Button(action: {    //Share Instagram Button
                    socialMediaSharing.shareToInstagram(post: post)
                }) {
                    Text("SHARE INSTAGRAM")
                }
                .buttonStyle()

                Button(action: {    //Share Twitter Button
                    socialMediaSharing.shareToTwitter(post: post)
                }) {
                    Text("SHARE\nX")
                }
                .buttonStyle()

                Button(action: {    //Download Button
                    viewModel.downloadContent(post: post)
                }) {
                    Image(systemName: "arrow.down.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .buttonStyle()
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
}
