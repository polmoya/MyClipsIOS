//
//  Post.swift
//  MyClipsIOS
//
//  Created by Pol Moya Betriu on 4/9/24.
//

import SwiftUI
import AVKit

// Definimos los tipos de medios que pueden ser imagen o video
enum MediaType {
    case image(URL)      // Imagen de alta calidad
    case video(URL)        // URL del video que se reproducirá
}

struct Post: Identifiable {
    let id = UUID()        // Identificador único
    let media: MediaType   // El tipo de media (imagen o video)
}

