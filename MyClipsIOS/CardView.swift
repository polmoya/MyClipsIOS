//
//  CardView.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 4/9/24.
//

import SwiftUI

struct CardView: View {
    let post: Post
    
    var body: some View {
        VStack {
            post.media
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 250)
                .clipped()
            
            HStack(spacing: 20) {
                Button(action: shareToInstagram) {
                    Text("Share to Instagram")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button(action: shareToTwitter) {
                    Text("Share to Twitter")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.teal)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
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
