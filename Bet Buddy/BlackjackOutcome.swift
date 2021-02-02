//
//  BlackjackOutcome.swift
//  Bet Buddy
//
//  Created by Jordan Lee on 2/2/21.
//

import Foundation

struct BlackjackOutcome : Codable {
    var playerID: Int
    var didBankerWin: Bool
    var multiplier: Int
}
