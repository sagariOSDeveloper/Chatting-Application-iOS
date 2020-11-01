//
//  NewConversationViewController.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 05/09/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit

class NewConversationViewController: UIViewController {
    
    
    private var users = [[String:String]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    public var completion: ((SearchResult)->(Void))?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",style: .done, target: self, action: #selector(dismissSelf))
        
        searchBar.becomeFirstResponder()
        setupView()
    }
    
    fileprivate lazy var noResultsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "No Results"
        l.font = UIFont.systemFont(ofSize: 21,weight: .medium)
        l.numberOfLines = -1
        l.textColor = .red
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()
    
    fileprivate lazy var searchBar: UISearchBar = {
        let s = UISearchBar()
        s.placeholder = "Search for Users..."
        s.delegate = self
        return s
    }()
    
    fileprivate lazy var tableView: UITableView = {
        let t = UITableView()
        t.isHidden = true
        t.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return t
    }()
    
    @objc fileprivate func dismissSelf(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupView() {
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.frame = view.bounds
        
        noResultsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        noResultsLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
        noResultsLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Start Conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true) {[weak self] in
            self?.completion?(targetUserData)
        }
    }
    
}


extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else { return }
        searchBar.resignFirstResponder()
        CircularLoadingView.showLoading()
        results.removeAll()
        self.searchUsers(query: text)
    }
    
    func searchUsers(query: String) {
        //Check if array has firebase results
        if hasFetched {
            //if it does then filter
            filterUsers(with: query)
        }
        else {
            //if not, fetch then filter
            DatabaseManager.shared.getAllUsers {[weak self] (result) in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users: \(error)")
                }
            }
        }
    }
    
    func filterUsers(with term: String) {
        //Update the UI: either show results or no results label
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        CircularLoadingView.hideLoading()
        let results: [SearchResult] = self.users.filter({
            guard let email = $0["email"], email != safeEmail else{
                return false
            }
            guard let name = $0["name"]?.lowercased() else{
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({ s in
            guard let email = s["email"], let name = s["name"] else{
                return nil
            }
            return SearchResult(name: name, email: email)
        })
//        .compactMap({
//
//            guard let email = $0["email"], let name = $0["name"] else{
//                return nil
//            }
//            return SearchResult(name: name, email: email)
//        })
        
        self.results = results
        
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        }else{
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

struct SearchResult {
    let name: String
    let email: String
}
