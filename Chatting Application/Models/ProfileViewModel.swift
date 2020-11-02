//
//  ProfileViewModel.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 02/11/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import Foundation

enum ProfileViewModelType {
    case info,logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (()->Void)?
}
