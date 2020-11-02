//
//  ChatModels.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 02/11/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation

struct Message: MessageType {
    
    public var sender: SenderType
    
    public var messageId: String
    
    public var sentDate: Date
    
    public var kind: MessageKind
    
}

struct Media: MediaItem {
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
}

extension MessageKind {
    
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
    
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

struct Sender: SenderType {
    
    var senderId: String
    
    var displayName: String
    
    var photoURL: String
    
}
