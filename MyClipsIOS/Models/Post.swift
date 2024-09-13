//
//  Post.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 4/9/24.
//

import Foundation
import SwiftUI
import AVKit

enum MediaType {
    case image(URL)
    case video(URL)
}

struct Post: Identifiable {
    let id = UUID()
    let media: MediaType
    let title: String
    let description: String
    let date: String

    var parsedDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: date)
    }
}
