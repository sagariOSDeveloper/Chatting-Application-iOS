//
//  ProfileViewController.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 05/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

class ProfileViewController: UIViewController {
    
    var data = [ProfileViewModel]()
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "name")as? String ?? "No Name")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email")as? String ?? "No Email")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            guard let strongSelf = self else {return}
            
            let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (UIAlertAction) in
                
                
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                //Facebook Logout
                FBSDKLoginKit.LoginManager().logOut()
                
                //Google Logout
                GIDSignIn.sharedInstance()?.signOut()
                
                //Firebase Logout
                do{
                    try FirebaseAuth.Auth.auth().signOut()
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: true)
                }catch{
                    print("Failed to log out")
                }
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
            strongSelf.present(actionSheet,animated: true)
        }))
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        navigationItem.largeTitleDisplayMode = .always
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.string(forKey: "email") else { return nil }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        let v = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 300))
        v.backgroundColor = .red
        
        let imageView = UIImageView(frame: CGRect(x: (v.frame.width-150)/2, y: 75, width: 150, height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.layer.masksToBounds = true
        v.addSubview(imageView)
        
        StorageManager.shared.downloadURL(with: path) { (result) in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to download URL: \(error)")
            }
        }
        return v
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setup(with: data[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setup(with viewModel: ProfileViewModel){
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
