//
//  ContentView.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 4/9/24.
//

import SwiftUI

struct ContentView: View {
    let posts: [Post] = [
        Post(
            media: .image(URL(string: "https://aguacatec.es/wp-content/uploads/2023/10/e5a978b8-6772-4c85-a50e-15581af7d483.png")!),
            title: "Post 1",
            description: "Description of the first post."),
        Post(
            media: .video(URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!),
            title: "Post 2",
            description: "Description of the second post."),
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
