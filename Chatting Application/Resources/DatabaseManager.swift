//
//  DatabaseManager.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 16/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String)->String{
        var safe = emailAddress.replacingOccurrences(of: ".", with: "-")
        safe = safe.replacingOccurrences(of: "@", with: "-")
        return safe
    }
}

//MARK: - Account Management
extension DatabaseManager {
    
    public func userExist(with email: String, completion: @escaping ((Bool)-> Void)){
        var safe = email.replacingOccurrences(of: ".", with: "-")
        safe = safe.replacingOccurrences(of: "@", with: "-")
        database.child(safe).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? String != nil else{
                //                If not found
                completion(false)
                return
            }
            //                If found.
            completion(true)
        }
    }
    
    
    // Inserts new user in Database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool)->Void){
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { (error, _) in
            guard error == nil else {
                print("Failed to save data to firebase")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
}

struct ChatAppUser {
    
    let emailAddress: String
    let firstName: String
    let lastName: String
    
    var safeEmail: String {
        var safe = emailAddress.replacingOccurrences(of: ".", with: "-")
        safe = safe.replacingOccurrences(of: "@", with: "-")
        return safe
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
    
}
