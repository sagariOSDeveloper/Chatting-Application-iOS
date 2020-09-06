
//
//  LoginViewController.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 05/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    var emailTextField: UITextField?
    var passwordTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Log In"
        view.backgroundColor = .white
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        setupView()
    }
    
    @objc func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func logginButtonTapped(){
        emailTextField?.resignFirstResponder()
        passwordTextField?.resignFirstResponder()
        guard let email = emailTextField!.text, let pass = passwordTextField!.text , !email.isEmpty, !pass.isEmpty, pass.count >= 6 else {
            alertUserLoginError()
            return
        }
        
//        Firebase Login
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
}


extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField?.becomeFirstResponder()
        }else if textField == passwordTextField {
            logginButtonTapped()
        }
        return true
    }
}
