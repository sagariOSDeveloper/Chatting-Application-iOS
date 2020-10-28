//
//  StorageManager.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 28/10/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    
    /*
     /images/baloch78609-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String,Error>)->Void
    
    ///Upload Picture to Firebase Storage and returns completion  with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data,metadata: nil) { [self] (metaData, error) in
            guard error == nil else{
                print("Failed to upload data")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("images/\(fileName)").downloadURL { (url, error) in
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
