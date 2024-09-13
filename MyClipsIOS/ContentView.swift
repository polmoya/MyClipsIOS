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
            description: "Description of the first post. This is the second oldest post",
            date: "2024-08-25 11:23:00"),
        Post(
            media: .video(URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!),
            title: "Post 2",
            description: "Description of the second post. This is the most recent post",
            date: "2024-08-25 10:23:00"),
        Post(
            media: .image(URL(string: "https://media.gettyimages.com/id/1231536207/photo/european-athletics-indoor-championships-day-1-session-2.jpg?s=594x594&w=gi&k=20&c=g2LMbchCTGRk8qYHvzCmMwBfGHIlirG-d2rmY7fMKjU=")!),
            title: "Post 3",
            description: "Description of the third post. The last but not least post. This is the oldest post",
            date: "2024-08-28 11:22:55"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(posts.sorted { ($0.parsedDate ?? Date()) > ($1.parsedDate ?? Date()) }) { post in
                    CardView(post: post)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.black).edgesIgnoringSafeArea(.all))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
