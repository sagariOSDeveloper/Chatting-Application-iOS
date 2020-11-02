//
//  ConversationTableViewCell.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 30/10/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit
import SDWebImage

class NewConversationCell: UITableViewCell {
    
    public static let identifier = "NewConversationCell"
    
    private lazy var userImageView: UIImageView = {
        let i = UIImageView()
        i.translatesAutoresizingMaskIntoConstraints = false
        i.contentMode = .scaleAspectFill
        i.layer.cornerRadius = 35
        i.layer.masksToBounds = true
        i.layer.borderColor = UIColor.red.cgColor
        i.layer.borderWidth = 2
        return i
    }()
    
    fileprivate lazy var userNameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 21, weight: .semibold)
        return l
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        userImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        userImageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        userImageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        
        userNameLabel.leftAnchor.constraint(equalTo: userImageView.rightAnchor, constant: 10).isActive = true
//        userNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15).isActive = true
//        userNameLabel.widthAnchor.constraint(equalToConstant: (contentView.frame.width - 20 - userImageView.frame.width)).isActive = true
//        userNameLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        userNameLabel.centerYAnchor.constraint(equalTo: userImageView.centerYAnchor).isActive = true
        
    }
    
    public func configure(with model: SearchResult) {
        userNameLabel.text = model.name
        
        let path = "images/\(model.email)_profile_picture.png"
        StorageManager.shared.downloadURL(with: path) {[weak self] (result) in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get image URL: \(error)")
            }
        }
    }
}

