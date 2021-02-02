//
//  BlackjackHost.swift
//  Bet Buddy
//
//  Created by Jordan Lee on 1/2/21.
//

import Foundation
import UIKit
import MultipeerConnectivity

class LobbyViewController : UIViewController {
    
    @IBOutlet weak var lblConnectivityType: UILabel!
    @IBOutlet weak var tvPlayers: UITableView!
    @IBOutlet weak var bStartGame: UIButton!
    
    @IBAction func sendStartGame(_ sender: Any) {
        do {
            let bbMessage = BBMessage(messageType: "start-game", message: nil, data: nil)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? mcSession.send(messageData, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    var connectivityType = "none"
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser!
    var players: [Player] = []
    var playerID: Int!
    let playerController = PlayerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if connectivityType == "host" {
            lblConnectivityType.text = "Blackjack Host"
            playerID = 0
            loadData()
        }
        else if connectivityType == "join" {
            lblConnectivityType.text = "Blackjack Join"
        }
        
        setupConnectivity()
        additionalStyling()
        hideControls()
        
        tvPlayers.delegate = self
        tvPlayers.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if connectivityType == "host" {
            hostRoom()
        }
        else if connectivityType == "join" {
            joinRoom()
        }
    }
    
    func additionalStyling() {
        
        let styleHelper = StyleHelper()
        
        // colour
        bStartGame.backgroundColor = Colours.primaryRed
        
        // rounded corners
        styleHelper.roundCorners(views: [bStartGame])
    }
    
    func hideControls() {
        if connectivityType != "host" {
            bStartGame.isHidden = true
        }
    }
    
    func setupConnectivity() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        print("Connectivity setup complete!")
    }
    
    func loadData() {
        if players.count == 0 {
            let hostPlayer = playerController.getCurrentPlayer()
            players.append(hostPlayer)
        }
        DispatchQueue.main.async {
            self.tvPlayers.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.destination is BlackjackViewController
        {
            let vc = segue.destination as! BlackjackViewController
            vc.connectivityType = self.connectivityType
            vc.peerID = self.peerID
            vc.mcSession = self.mcSession
            vc.players = self.players
            vc.playerID = self.playerID
        }
    }
    
    func hostRoom() {
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "bb-rm")
        nearbyServiceAdvertiser.delegate = self
        nearbyServiceAdvertiser.startAdvertisingPeer()
        print("Room now discoverable!")
    }
    
    func joinRoom() {
        let mcBrowser = MCBrowserViewController(serviceType: "bb-rm", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
        print("Searching for rooms...")
    }
    
    func processMessage(bbMsg: BBMessage) {
        let msgType = bbMsg.messageType
        
        switch msgType {
        case "join":
            if connectivityType == "host" {
                do {
                    let newPlayer = try JSONDecoder().decode(Player.self, from: bbMsg.data!)
                    addPlayer(newPlayer: newPlayer)
                    sendCurrentPlayers()
                    
                    DispatchQueue.main.async {
                        self.tvPlayers.reloadData()
                    }
                } catch {
                    fatalError("Unable to process the received data.")
                }
            }
            
        case "current-players":
            do {
                let currentPlayers = try JSONDecoder().decode([Player].self, from: bbMsg.data!)
                players = currentPlayers
                
                playerID = Int(bbMsg.message!)
                
                DispatchQueue.main.async {
                    self.tvPlayers.reloadData()
                }
            } catch {
                fatalError("Unable to process the received data.")
            }
            
        case "start-game":
            if connectivityType == "connected" {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "startBlackjack", sender: self)
                }
            }
            
        default:
            print("Lobby.swift: Unrecognised message [\(msgType)]")
        }
    }
    
    func addPlayer(newPlayer: Player) {
        players.append(newPlayer)
    }
    
    func sendJoinMessage() {
        if connectivityType == "connected" {
            do {
                let player = playerController.getCurrentPlayer()
                let playerData = try JSONEncoder().encode(player)
                let bbMessage = BBMessage(messageType: "join", message: nil, data: playerData)
                let messageData = try JSONEncoder().encode(bbMessage)
                
                try? mcSession.send(messageData, toPeers: mcSession.connectedPeers, with: .reliable)
            } catch {
                fatalError("Unable to encode player details.")
            }
        }
    }
    
    func sendCurrentPlayers() {
        do {
            let currentPlayersData = try JSONEncoder().encode(players)
            let bbMessage = BBMessage(messageType: "current-players", message: String(players.count-1), data: currentPlayersData)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? mcSession.send(messageData, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
}

extension LobbyViewController : MCSessionDelegate {
    
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

extension LobbyViewController : MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
        connectivityType = "connected"
        sendJoinMessage()
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
        connectivityType = "none"
    }
}

extension LobbyViewController : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, mcSession)
    }
}

extension LobbyViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LobbyPlayerTableViewCell") as! LobbyPlayerTableViewCell
        
        let player = players[indexPath.row]
        cell.lblPlayerName.text = player.name
        cell.lblPlayerTitle.text = player.title
        if player.profilePicture != nil {
            //cell.ivPlayerProfilePicture.image = player.profilePicture
            
        }
        
        return cell
    }
}

class LobbyPlayerTableViewCell : UITableViewCell {
    
    @IBOutlet weak var ivPlayerProfilePicture: UIImageView!
    @IBOutlet weak var lblPlayerName: UILabel!
    @IBOutlet weak var lblPlayerTitle: UILabel!
    
}
