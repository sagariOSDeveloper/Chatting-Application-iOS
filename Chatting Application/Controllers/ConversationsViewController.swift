//
//  ViewController.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 05/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit
import Firebase

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        validateAuth()
    }
    
    fileprivate func validateAuth(){
        if Firebase.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
}

