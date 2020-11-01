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
    
    public var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        setupView()
        fetchConversations()
        startListeningForConversations()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main) {[weak self] (_) in
            guard let strongSelf = self else{
                return
            }
            strongSelf.startListeningForConversations()
        }
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
            guard let strongSelf = self else { return }
            let currentConversations = strongSelf.conversations
            
            if let targetConversation = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.title = targetConversation.name
                vc.isNewConversation = false
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }else{
                strongSelf.createNewConverstaion(result: result)
            }
            print("Result in TapCompse: \(result)")
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    fileprivate func createNewConverstaion(result: SearchResult){
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        // Check in database if conversation exists with these two users
        // If it does, reuse same conversation id
        // Otherwise, use existring code
        DatabaseManager.shared.conversationExist(with: email) {[weak self] (result) in
            guard let strongSelf = self else { return }
            switch result {
            case.success(let conversationId):
                let vc = ChatViewController(with: email, id: conversationId)
                vc.title = name
                vc.isNewConversation = false
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case.failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.title = name
                vc.isNewConversation = true
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    fileprivate func validateAuth(){
        if Firebase.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    private func fetchConversations(){
        //Fetch Conversations from Firestore
        conversationTableView.isHidden = false
    }
    
    private func startListeningForConversations(){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else { return }
        print("started Listening")
        if let observer = loginObserver {
            print("Removing Observer")
            NotificationCenter.default.removeObserver(observer)
        }
        
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
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(with: model)
    }
    
    func openConversation(with model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail,id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            DatabaseManager.shared.deleteConversation(converdsationId: conversationId) {[weak self] (success) in
                if success{
                    print("Finally Deleted")
                    self?.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                }else{
                    print("Finally Not Deleted")
                }
            }
            tableView.endUpdates()
        }
    }
}
