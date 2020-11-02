//
//  StorageManager.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 28/10/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import Foundation
import FirebaseStorage

///Allows you to get, fetch and upload files to firebase storage
final class StorageManager {
    
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    private init(){}
    
    /*
     /images/baloch78609-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String,Error>)->Void
    
    ///Upload Picture to Firebase Storage and returns completion  with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data,metadata: nil) { [weak self] (metaData, error) in
            guard let strongSelf = self else{ return }
            guard error == nil else{
                print("Failed to upload data")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            strongSelf.storage.child("images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else{
                    print("failed To Get Download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL Returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    ///Upload Picture to Firebase Storage that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] (metaData, error) in
            guard error == nil else {
                print("Failed to upload data")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("message_images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else{
                    print("failedToGetDownloadURL")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL Returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    ///Upload Video to Firebase Storage that will be sent in a conversation message
    public func uploadMessageVideo(with fileURL: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileURL, metadata: nil) { [weak self] (metaData, error) in
            guard error == nil else{
                print("Failed to upload video")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("message_videos/\(fileName)").downloadURL { (url, error) in
                guard let url = url else{
                    print("failedToGetDownloadURL")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL Returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    
    public func downloadURL(with path: String, completion: @escaping (Result<URL ,Error>)->Void) {
        let refernce = storage.child(path)
        refernce.downloadURL { (url, error) in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadURL))
                return
            }
            completion(.success(url))
        }
    }
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
}
