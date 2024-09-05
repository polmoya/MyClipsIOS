//
//  Post.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 4/9/24.
//

import Foundation

import SwiftUI

struct Post: Identifiable {
    let id = UUID() // Esto hace que cada `Post` tenga un identificador único.
    let media: Image // Representa la imagen asociada a la publicación.
    let mediaURL: URL // La URL de la imagen o video.
}
