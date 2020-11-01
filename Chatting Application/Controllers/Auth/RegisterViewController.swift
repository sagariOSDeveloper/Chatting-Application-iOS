//
//  RegisterViewController.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 05/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    var emailTextField: UITextField?
    var passwordTextField: UITextField?
    var firstNameTextField: UITextField?
    var lastNameTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Log In"
        view.backgroundColor = .systemBackground
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        setupView()
    }
    
    @objc private func didTapRegister(){
        //        let vc = RegisterViewController()
        //        vc.title = "Create Account"
        //        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @objc private func changeProfilePic(){
        print("Change profile pic called")
        presentPhotoActionSheet()
    }
    
    @objc func registerButtonTapped(){
        //        spinner.show(in: view)
        emailTextField?.resignFirstResponder()
        passwordTextField?.resignFirstResponder()
        firstNameTextField?.resignFirstResponder()
        lastNameTextField?.resignFirstResponder()
        guard let email = emailTextField!.text,
              let pass = passwordTextField!.text ,
              let firstName = firstNameTextField!.text,
              let lastName = lastNameTextField!.text,
              !email.isEmpty,
              !pass.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              pass.count >= 6
        else {
            alertUserLoginError()
            return
        }
        
        CircularLoadingView.showLoading()
        DatabaseManager.shared.userExist(with: email) {[weak self] (exist) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard !exist else{
                //User Already Exist
                //                strongSelf.spinner.dismiss()
                CircularLoadingView.hideLoading()
                strongSelf.alertUserLoginError(message: "A user Account for that email already exists.")
                return
            }
            
            //Firebase Register
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: pass, completion: {(authResult,error) in
                
                guard authResult != nil, error == nil else {
                    return
                }
                
                
                //                strongSelf.spinner.dismiss()
                let chatUser = ChatAppUser(emailAddress: email, firstName: firstName, lastName: lastName)
                DatabaseManager.shared.insertUser(with: chatUser) { (success) in
                    if success {
                        //Upload picture
                        
                        guard let image = strongSelf.profilePic.image, let data = image.pngData() else {
                            return
                        }
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
                    }
                }
                CircularLoadingView.hideLoading()
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    func alertUserLoginError(message: String = "Please enter all information to create a new account."){
        let alert = UIAlertController(title: "Woops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert,animated: true)
    }
    
    
    
    
    
    
    
    
    
    
    fileprivate func setupView(){
        view.addSubview(profilePic)
        profilePic.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10).isActive = true
        profilePic.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profilePic.heightAnchor.constraint(equalToConstant: 100).isActive = true
        profilePic.widthAnchor.constraint(equalToConstant: 100).isActive = true
        profilePic.clipsToBounds = true
        profilePic.layer.cornerRadius = 50
    
        let emailField = getTextField(placeHolder: "Email Address...", secureEntry: false)
        view.addSubview(emailField)
        emailField.topAnchor.constraint(equalTo: profilePic.bottomAnchor,constant: 40).isActive = true
        emailField.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        emailField.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        let firstNameField = getTextField(placeHolder: "First Name...", secureEntry: false)
        view.addSubview(firstNameField)
        firstNameField.topAnchor.constraint(equalTo: emailField.bottomAnchor,constant: 20).isActive = true
        firstNameField.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        firstNameField.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        let lastNameField = getTextField(placeHolder: "Last Name...", secureEntry: false)
        view.addSubview(lastNameField)
        lastNameField.topAnchor.constraint(equalTo: firstNameField.bottomAnchor,constant: 20).isActive = true
        lastNameField.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        lastNameField.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        let passwordField = getTextField(placeHolder: "Password", secureEntry: true)
        view.addSubview(passwordField)
        passwordField.topAnchor.constraint(equalTo: lastNameField.bottomAnchor,constant: 20).isActive = true
        passwordField.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        passwordField.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        view.addSubview(registerButton)
        registerButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor,constant: 30).isActive = true
        registerButton.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 30).isActive = true
        registerButton.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -30).isActive = true
        
        emailTextField = (emailField.subviews[0] as! UITextField)
        passwordTextField = (passwordField.subviews[0] as! UITextField)
        firstNameTextField = (firstNameField.subviews[0] as! UITextField)
        lastNameTextField = (lastNameField.subviews[0] as! UITextField)
        
        emailTextField?.delegate = self
        passwordTextField?.delegate = self
        firstNameTextField?.delegate = self
        lastNameTextField?.delegate = self
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
    
    fileprivate lazy var registerButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 40).isActive = true
        b.setTitle("Register", for: .normal)
        b.setTitleColor(.red, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        b.backgroundColor = .white
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        b.layer.cornerRadius = 10
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.red.cgColor
        return b
    }()
    
    fileprivate lazy var profilePic: UIImageView = {
        var i = UIImageView()
        i.translatesAutoresizingMaskIntoConstraints = false
        i.image = UIImage(systemName: "person.circle")
        i.tintColor = .red
        i.isUserInteractionEnabled = true
        i.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeProfilePic)))
        i.contentMode = .scaleAspectFit
        i.layer.masksToBounds = true
        i.layer.borderWidth = 1
        i.layer.borderColor = UIColor.red.cgColor
        return i
    }()
    
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a profile picture.", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoLibrary()
        }))
        present(actionSheet,animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
    }
    
    func presentPhotoLibrary() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.profilePic.image = selectedImage
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}



extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField?.becomeFirstResponder()
        }else if textField == passwordTextField {
            registerButtonTapped()
        }
        return true
    }
}
