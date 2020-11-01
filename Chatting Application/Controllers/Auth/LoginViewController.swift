
//
//  LoginViewController.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 05/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    var emailTextField: UITextField?
    var passwordTextField: UITextField?
    private var loginObserver: NSObjectProtocol?
    let loadingView = CircularLoadingView.loadingView
    //    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main) {[weak self] (_) in
            guard let strongSelf = self else{
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        GIDSignIn.sharedInstance()?.presentingViewController = self
        self.title = "Log In"
        view.backgroundColor = .systemBackground
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        setupView()
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func logginButtonTapped(){
        //        spinner.show(in: view)
        emailTextField?.resignFirstResponder()
        passwordTextField?.resignFirstResponder()
        guard let email = emailTextField!.text, let pass = passwordTextField!.text , !email.isEmpty, !pass.isEmpty, pass.count >= 6 else {
            alertUserLoginError()
            return
        }
        CircularLoadingView.showLoading()
        
        //        Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: pass, completion: {[weak self] (sucess, error) in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                CircularLoadingView.hideLoading()
            }
            
            guard let result = sucess, error == nil else {
                return
            }
            UserDefaults.standard.set(email,forKey: "email")
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail) {  (result) in
                switch result{
                case.success(let data):
                    guard let userData = data as? [String:Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else { return }
                    UserDefaults.standard.set("\(firstName) \(lastName)",forKey: "name")
                    NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                case.failure(let error):
                    print("Failed to get the data: \(error)")
                }
            }
            
            print("Logged In: \(result.user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil )
        })
        
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Woops", message: "Please enter all information to log in.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert,animated: true)
    }
    
    
    
    
    
    
    
    
    
    
    fileprivate func setupView(){
        view.addSubview(appIcon)
        appIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40).isActive = true
        appIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        appIcon.heightAnchor.constraint(equalTo: view.widthAnchor,multiplier: 0.25).isActive = true
        
        let emailField = getTextField(placeHolder: "Email Address...", secureEntry: false)
        view.addSubview(emailField)
        emailField.topAnchor.constraint(equalTo: appIcon.bottomAnchor,constant: 50).isActive = true
        emailField.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        emailField.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        let passwordField = getTextField(placeHolder: "Password", secureEntry: true)
        view.addSubview(passwordField)
        passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor,constant: 20).isActive = true
        passwordField.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        passwordField.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        view.addSubview(loginButton)
        loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor,constant: 30).isActive = true
        loginButton.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        loginButton.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        view.addSubview(facebookLoginButton)
        facebookLoginButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor,constant: 30).isActive = true
        facebookLoginButton.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        facebookLoginButton.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        view.addSubview(googleLoginButton)
        googleLoginButton.topAnchor.constraint(equalTo: facebookLoginButton.bottomAnchor,constant: 30).isActive = true
        googleLoginButton.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        googleLoginButton.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        emailTextField = (emailField.subviews[0] as! UITextField)
        passwordTextField = (passwordField.subviews[0] as! UITextField)
        
        emailTextField?.delegate = self
        passwordTextField?.delegate = self
    }
    
    fileprivate func getTextField(placeHolder: String, secureEntry: Bool)-> UIView {
        
        let e = UITextField()
        e.translatesAutoresizingMaskIntoConstraints = false
        e.heightAnchor.constraint(equalToConstant: 30).isActive = true
        e.autocorrectionType = .no
        e.autocapitalizationType = .none
        e.layer.cornerRadius = 12
        e.layer.borderColor = UIColor.lightGray.cgColor
        e.returnKeyType = .continue
        e.borderStyle = .none
        e.backgroundColor = .none
        e.placeholder = placeHolder
        e.isSecureTextEntry = secureEntry
        
        if e.isSecureTextEntry {
            e.returnKeyType = .done
        }
        
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        v.backgroundColor = .red
        
        let f = UIView()
        f.translatesAutoresizingMaskIntoConstraints = false
        f.addSubview(e)
        
        e.topAnchor.constraint(equalTo: f.topAnchor).isActive = true
        e.leftAnchor.constraint(equalTo: f.leftAnchor).isActive = true
        e.rightAnchor.constraint(equalTo: f.rightAnchor).isActive = true
        e.bottomAnchor.constraint(equalTo: f.bottomAnchor,constant: -1).isActive = true
        
        f.addSubview(v)
        v.leftAnchor.constraint(equalTo: f.leftAnchor).isActive = true
        v.rightAnchor.constraint(equalTo: f.rightAnchor).isActive = true
        v.bottomAnchor.constraint(equalTo: f.bottomAnchor).isActive = true
        
        return f
        
    }
    
    fileprivate lazy var loginButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 40).isActive = true
        b.setTitle("Login", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        b.backgroundColor = .red
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(logginButtonTapped), for: .touchUpInside)
        b.layer.cornerRadius = 10
        return b
    }()
    
    fileprivate lazy var appIcon: UIImageView = {
        let i = UIImageView()
        i.translatesAutoresizingMaskIntoConstraints = false
        i.image = UIImage(named: "Simple_Logo")
        i.contentMode = .scaleAspectFit
        return i
    }()
    
    fileprivate lazy var facebookLoginButton: FBLoginButton = {
        let fb = FBLoginButton()
        fb.translatesAutoresizingMaskIntoConstraints = false
        fb.delegate = self
        fb.heightAnchor.constraint(equalToConstant: 40).isActive = true
        fb.clipsToBounds = true
        fb.layer.cornerRadius = 10
        fb.permissions = ["email,public_profile"]
        return fb
    }()
    
    fileprivate lazy var googleLoginButton: GIDSignInButton = {
        let gb = GIDSignInButton()
        gb.translatesAutoresizingMaskIntoConstraints = false
        return gb
    }()
}


extension LoginViewController: UITextFieldDelegate, LoginButtonDelegate{
    //MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField?.becomeFirstResponder()
        }else if textField == passwordTextField {
            logginButtonTapped()
        }
        return true
    }
    
    //MARK: - Facebook Login Button Delegate
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User Failed to login with Facebook")
            return
        }
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields": "email, first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        
        facebookRequest.start { (_, result, err) in
            guard let result = result as? [String: Any], err == nil else {
                print("Failed to make facebook graph request")
                return
            }
            print("Result: \(result)")
            
            //            return
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String:Any],
                  let data = picture["data"] as? [String:Any],
                  let pictureURL = data["url"] as? String else {
                print("Failed to get email and name from FB Result")
                return
            }
            UserDefaults.standard.set(email,forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)",forKey: "name")
            
            DatabaseManager.shared.userExist(with: email) { (exists ) in
                if !exists {
                    let chatUser = ChatAppUser(emailAddress: email, firstName: firstName, lastName: lastName)
                    DatabaseManager.shared.insertUser(with: chatUser) { (success) in
                        if success {
                            guard let url = URL(string: pictureURL) else {
                                return
                            }
                            
                            print("Downloading data from facebook")
                            
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else {
                                    print("Failed to Downloading data from facebook")
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
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) {[weak self] (authResult, error) in
                guard let strongSelf = self else{
                    return
                }
                guard authResult != nil, error == nil else{
                    if let err = error {
                        print("Failed to Login\(err)")
                    }
                    return
                }
                print("Login Success...!")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("Log out")
    }
}


