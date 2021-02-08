//
//  Home.swift
//  Bet Buddy
//
//  Created by Jordan Lee on 31/1/21.
//

import Foundation
import UIKit
import MultipeerConnectivity

class HomeViewController : UIViewController {
    
    @IBOutlet weak var vMain: UIView!
    @IBOutlet weak var svAvailable: UIStackView!
    @IBOutlet weak var svComingSoon: UIStackView!
    @IBOutlet weak var vBlackjack: UIView!
    @IBOutlet weak var ivBlackjack: UIImageView!
    @IBOutlet weak var vMahjong: UIView!
    @IBOutlet weak var ivMahjong: UIImageView!
    @IBOutlet weak var vBlackjackFront: UIView!
    @IBOutlet weak var vBlackjackFlipped: UIView!
    @IBOutlet weak var vMahjongFront: UIView!
    @IBOutlet weak var vMahjongFlipped: UIView!
    
    var flipStatuses: [String: Bool] = [ "blackjack": false, "mahjong": false ]
    var connectivityType = "join"
    var mcSession: MCSession? = nil
    
    @IBAction func flipActionBlackjack(_ sender: Any) {
        flipGamemode(gamemodeName: "blackjack")
    }
    
    @IBAction func flipActonMahjong(_ sender: Any) {
        flipGamemode(gamemodeName: "mahjong")
    }
    @IBAction func clickHostBlackjack(_ sender: Any) {
        connectivityType = "host"
    }
    @IBAction func clickJoinBlackjack(_ sender: Any) {
        connectivityType = "join"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if mcSession != nil {
            mcSession?.disconnect()
        }
        additionalStyling()
    }
    
    // set white status bar text
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is LobbyViewController
        {
            let vc = segue.destination as! LobbyViewController
            vc.connectivityType = self.connectivityType
        }
    }
    
    func additionalStyling() {
        
        let styleHelper = StyleHelper()
        
        // colour
        svAvailable.backgroundColor = Colours.primaryRed
        svComingSoon.backgroundColor = Colours.primaryRed
        vBlackjackFlipped.backgroundColor = Colours.tintRed
        vMahjongFlipped.backgroundColor = Colours.tintRed
        view.backgroundColor = Colours.backgroundRed
        vMain.backgroundColor = Colours.backgroundRed
        
        // rounded corners
        styleHelper.roundCorners(views: [svAvailable, svComingSoon, vBlackjack, vMahjong, ivBlackjack, ivMahjong, vBlackjackFront, vBlackjackFlipped, vMahjongFront, vMahjongFlipped])
        
    }
    
    func flipGamemode(gamemodeName: String) {
        let allCardSides: [String: [String: UIView]] = [
            "blackjack": ["front": vBlackjackFront, "flipped": vBlackjackFlipped],
            "mahjong": ["front": vMahjongFront, "flipped": vMahjongFlipped]
        ]
        
        let gamemodeCardFront = allCardSides[gamemodeName]!["front"]
        let gamemodeCardFlipped = allCardSides[gamemodeName]!["flipped"]
        
        var gamemodeCard: UIView = vBlackjack
        if gamemodeName == "blackjack" {
            gamemodeCard = vBlackjack
        }
        else if gamemodeName == "mahjong" {
            gamemodeCard = vMahjong
        }
        
        let isFlipped = flipStatuses[gamemodeName]!
        guard let displayView = isFlipped ? gamemodeCardFlipped : gamemodeCardFront else { return }
        UIView.transition(with: gamemodeCard, duration: 0.3,
                            options: isFlipped ? .transitionFlipFromRight: .transitionFlipFromLeft,
                            animations: { () -> Void in
                                gamemodeCard.insertSubview(displayView, at: 0)
                            }, completion: nil)
        
        flipStatuses[gamemodeName] = !isFlipped
        
        unflipGamemodes(except: gamemodeName)
    }
    
    func unflipGamemodes(except: String) {
        let allCardSides: [String: [String: UIView]] = [
            "blackjack": ["front": vBlackjackFront, "flipped": vBlackjackFlipped],
            "mahjong": ["front": vMahjongFront, "flipped": vMahjongFlipped]
        ]
        
        for card in allCardSides {
            if except != card.key {
                
                var gamemodeCard: UIView = vBlackjack
                if card.key == "blackjack" {
                    gamemodeCard = vBlackjack
                }
                else if card.key == "mahjong" {
                    gamemodeCard = vMahjong
                }
                
                let isFlipped = flipStatuses[card.key]!
                if isFlipped == true {
                    guard let displayView = isFlipped ? card.value["flipped"] : card.value["front"] else { return }
                    UIView.transition(with: gamemodeCard, duration: 0.3,
                                        options: isFlipped ? .transitionFlipFromRight: .transitionFlipFromLeft,
                                        animations: { () -> Void in
                                            gamemodeCard.insertSubview(displayView, at: 0)
                                        }, completion: nil)
                    
                    flipStatuses[card.key] = !isFlipped
                }
            }
        }
    }
}
