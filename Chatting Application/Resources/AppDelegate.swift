//
//  AppDelegate.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 05/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with google: \(error)")
            }
            return
        }
        
        print("Did sign in  with Googel: \(user)")
        
        guard let email = user.profile.email,
              let firstName = user.profile.givenName,
              let lastName = user.profile.familyName else {
            return
        }
        
        UserDefaults.standard.set(email,forKey: "email")
        UserDefaults.standard.set("\(firstName) \(lastName)",forKey: "name")
        
        DatabaseManager.shared.userExist(with: email) { (exist) in
            if !exist {
                let chatUser = ChatAppUser(emailAddress: email, firstName: firstName, lastName: lastName)
                DatabaseManager.shared.insertUser(with: chatUser) { (success) in
                    if success {
                        if user.profile.hasImage {
                            
                            //Upload picture
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            
                            print("Downloading data from Google")
                            
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else {
                                    print("Failed to Downloading data from Google")
                                    return
                                }
                                
                                print("Got Data, Uploading...")
                                //Upload picture
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                                    switch result{
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL,forKey: "profile_picture_url")
                                        print("Download URL: \(downloadURL)")
                                    case .failure(let error):
                                        print("Storage Manager Error \(error)")
                                    }
                                }
                            }.resume()
                        }
                    }
                }
            }
        }
        
        guard let authentication = user.authentication else {
            print("Missing Auth Object of Google User")
            return
        }
        
        let credentials = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credentials) { (result, error) in
            guard let authResult = result, error == nil else {
                print("Failed to login with Google Credentials")
                return
            }
            print("Successfully Signed In with Google")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didLoginNotification"), object: nil)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was disconnected")
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}
