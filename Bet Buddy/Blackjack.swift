//
//  Blackjack.swift
//  Bet Buddy
//
//  Created by Jordan Lee on 2/2/21.
//

import Foundation
import UIKit
import MultipeerConnectivity

class BlackjackViewController : UIViewController {
    
    @IBOutlet weak var tvPlayers: UITableView!
    @IBOutlet weak var bStartRound: UIButton!
    @IBOutlet weak var bEndGame: UIButton!
    @IBOutlet weak var svHostBottomControls: UIStackView!
    @IBOutlet weak var bPlaceBet: UIButton!
    @IBOutlet weak var lblPhase: UILabel!
    
    var connectivityType = "none"
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var players: [Player] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPlayers()
        setupConnectivity()
        additionalStyling()
        hideControls()
        
        tvPlayers.delegate = self
        tvPlayers.dataSource = self
    }
    
    func additionalStyling() {
        
        let styleHelper = StyleHelper()
        
        // colour
        bStartRound.backgroundColor = Colours.primaryRed
        bEndGame.backgroundColor = Colours.primaryRed
        bPlaceBet.backgroundColor = Colours.primaryRed
        
        // rounded corners
        styleHelper.roundCorners(views: [bStartRound, bEndGame, bPlaceBet])
    }
    
    func hideControls() {
        print(connectivityType)
        if connectivityType != "host" {
            svHostBottomControls.isHidden = true
        }
        else {
            bPlaceBet.isHidden = true
        }
    }
    
    func setupConnectivity() {
        mcSession.delegate = self
    }
    
    func loadPlayers() {
        DispatchQueue.main.async {
            self.tvPlayers.reloadData()
        }
    }
    
    func sendBettingPhase() {
        
    }
    
    func processMessage(bbMsg: BBMessage) {
        let msgType = bbMsg.messageType
        
        switch msgType {
        case "join":
            return
            
        case "current-players":
            return
            
        default:
            print("Unrecognised message.")
        }
    }
}

extension BlackjackViewController : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not connected: \(peerID.displayName)")
        @unknown default:
            fatalError()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let bbMessage = try JSONDecoder().decode(BBMessage.self, from: data)
            processMessage(bbMsg: bbMessage)
        } catch {
            fatalError("Unable to process the received data.")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}

extension BlackjackViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlackjackPlayerTableViewCell") as! BlackjackPlayerTableViewCell
        
        let player = players[indexPath.row]
        cell.lblPlayerName.text = player.name
        cell.lblPlayerTitle.text = player.title
        if player.profilePicture != nil {
            //cell.ivPlayerProfilePicture.image = player.profilePicture
            
        }
        
        return cell
    }
}

class BlackjackPlayerTableViewCell : UITableViewCell {
    
    @IBOutlet weak var lblPlayerName: UILabel!
    @IBOutlet weak var lblPlayerTitle: UILabel!
    @IBOutlet weak var ivPlayerProfilePicture: UIImageView!
}
