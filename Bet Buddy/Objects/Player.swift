//
//  Player.swift
//  Bet Buddy
//
//  Created by Jordan Lee on 2/2/21.
//

import Foundation
import UIKit

struct Player : Codable {
    var name: String
    var title: String
    var profilePicture: String?
    var playerID: Int?
    var balance: Double?
    var roundBet: Double?
}
