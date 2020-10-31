//
//  ViewController.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 05/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit
import Firebase
import JGProgressHUD

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}

class ConversationsViewController: UIViewController {
    
    private var conversations = [Conversation]()
    
    fileprivate lazy var noConversationLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "No Conversations!"
        l.font = UIFont.systemFont(ofSize: 21,weight: .medium)
        l.numberOfLines = -1
        l.textColor = .gray
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()
    
    fileprivate lazy var conversationTableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        setupView()
        fetchConversations()
        startListeningForConversations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        validateAuth()
    }
    
    fileprivate func setupView(){
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        
        conversationTableView.delegate = self
        conversationTableView.dataSource = self
        view.addSubview(conversationTableView)
        conversationTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        conversationTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        conversationTableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        conversationTableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        
        view.addSubview(noConversationLabel)
        
        
    }
    
    @objc fileprivate func didTapComposeButton(){
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            print("Result in TapCompse: \(result)")
            self?.createNewConverstaion(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    fileprivate func createNewConverstaion(result: SearchResult){
        let name = result.name
        let email = result.email
        
        let vc = ChatViewController(with: email, id: nil)
        vc.title = name
        vc.isNewConversation = true
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    fileprivate func validateAuth(){
        if Firebase.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    fileprivate func fetchConversations(){
        //Fetch Conversations from Firestore
        conversationTableView.isHidden = false
    }
    
    fileprivate func startListeningForConversations(){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else { return }
        print("Starting Fetching Conversations...")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        DatabaseManager.shared.getAllConversations(for: safeEmail) {[weak self] (result) in
            switch result{
            case .success(let conversation):
                print("Successfully get conversation model\(conversation.count)")
                guard !conversation.isEmpty else {
                    return
                }
                self?.conversations = conversation
                DispatchQueue.main.async {
                    self?.conversationTableView.reloadData()
                }
            case .failure(let error):
                print("failed to get conversations \(error)")
            }
        }
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
//        cell.textLabel!.text = "Hello World"
//        cell.accessoryType = .disclosureIndicator
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        let vc = ChatViewController(with: model.otherUserEmail,id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
