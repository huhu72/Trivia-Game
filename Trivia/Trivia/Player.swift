//
//  Player.swift
//  Trivia
//
//  Created by Spencer Kinsey-Korzym on 5/4/22.
//

import UIKit
struct Player: Codable{
    var name:String
    var profileImageData: Data
    
    init(name: String, imageData: Data){
        self.name = name
        self.profileImageData = imageData
    }
    
}
