//
//  ContentView.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 4/9/24.
//

import SwiftUI

struct ContentView: View {
    let posts: [Post] = [
        Post(media: Image("exampleImage1"), mediaURL: URL(string: "https://example.com/image1")!),
        Post(media: Image("exampleImage2"), mediaURL: URL(string: "https://example.com/image2")!)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(posts) { post in
                    CardView(post: post)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
    }
}
