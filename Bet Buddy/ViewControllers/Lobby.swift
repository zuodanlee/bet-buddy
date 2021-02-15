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
    @IBOutlet weak var bReady: UIButton!
    @IBOutlet weak var bCancel: UIButton!
    @IBOutlet weak var bAdjustBalance: UIButton!
    
    @IBAction func adjustBalance(_ sender: Any) {
        
        if connectivityType == "connected" || connectivityType == "host" {
            let alertView = UIAlertController(title: "Adjust Starting Balance",
                                              message: "Please enter your desired amount.",
                                              preferredStyle: .alert)
            alertView.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "1"
            }
            alertView.addAction(UIAlertAction(title: "Cancel",
                                              style: .cancel,
                                              handler: { (_) in
                                                alertView.dismiss(animated: true, completion: nil)
            }))
            alertView.addAction(UIAlertAction(title: "Confirm",
                                              style: .default,
                                              handler: { (_) in
                                                let rawInput = alertView.textFields![0].text!
                                                var startBal = Double(rawInput)
                                                if startBal != nil {
                                                    if startBal! < 0 {
                                                        alertView.message = "Please enter a number more than 0."
                                                        self.present(alertView, animated: true, completion: nil)
                                                    }
                                                    else {
                                                        // valid input - proceed with starting balance change
                                                        startBal = Double(String(format: "%.2f", startBal!)) // round starting balance to 2dp
                                                        self.adjustPlayerBalance(newBal: startBal!)
                                                        self.sendCurrentPlayers()
                                                        self.loadData()
                                                    }
                                                }
                                                else {
                                                    alertView.message = "'\(rawInput)' is not a number."
                                                    self.present(alertView, animated: true, completion: nil)
                                                }
            }))
            self.present(alertView, animated: true, completion: nil)
        }
    }
    @IBAction func sendReady(_ sender: Any) {
        if connectivityType == "connected" {
            appDelegate.players[appDelegate.getPlayerIndex()].isReady = true
            sendCurrentPlayers()
            playerReadyStyle(isReady: true)
            
            loadData()
        }
    }
    @IBAction func sendCancel(_ sender: Any) {
        if connectivityType == "connected" {
            appDelegate.players[appDelegate.getPlayerIndex()].isReady = false
            sendCurrentPlayers()
            playerReadyStyle(isReady: false)
            
            loadData()
        }
    }
    @IBAction func sendStartGame(_ sender: Any) {
        if appDelegate.players.count > 1 {
            if allPlayersReady() {
                do {
                    let bbMessage = BBMessage(messageType: "start-game", message: nil, data: nil)
                    let messageData = try JSONEncoder().encode(bbMessage)
                    
                    try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
                } catch {
                    fatalError("Unable to encode player details.")
                }
            }
        }
    }
    
    var connectivityType = "none"
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let playerController = PlayerController()
    var rejoinPhase: String?
    var betCountdown: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.players = []
        
        if connectivityType == "host" {
            lblConnectivityType.text = "Blackjack Host"
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
        
        if rejoinPhase != nil {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "startBlackjack", sender: self)
            }
        }
    }
    
    func additionalStyling() {
        
        let styleHelper = StyleHelper()
        
        // colour
        bStartGame.backgroundColor = Colours.primaryRed
        bReady.backgroundColor = Colours.primaryRed
        bCancel.backgroundColor = Colours.primaryRed
        bAdjustBalance.backgroundColor = Colours.primaryRed
        
        // rounded corners
        styleHelper.roundCorners(views: [bStartGame, bReady, bCancel, bAdjustBalance])
    }
    
    func hideControls() {
        
        bCancel.isHidden = true
        
        if connectivityType != "host" {
            bStartGame.isHidden = true
        }
        else {
            bReady.isHidden = true
        }
    }
    
    func setupConnectivity() {
        appDelegate.peerID = MCPeerID(displayName: UIDevice.current.name)
        appDelegate.mcSession = MCSession(peer: appDelegate.peerID, securityIdentity: nil, encryptionPreference: .required)
        appDelegate.mcSession.delegate = self
        print("Connectivity setup complete!")
    }
    
    func loadData() {
        if appDelegate.players.count == 0 {
            var hostPlayer = playerController.getCurrentPlayer()
            hostPlayer.isReady = true
            appDelegate.players.append(hostPlayer)
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
            vc.countdown = betCountdown
            
            if rejoinPhase != nil {
                vc.phase = rejoinPhase!
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if let ident = identifier {
            if ident == "startBlackjack" {
                if appDelegate.players.count < 2 {
                    let alertView = UIAlertController(title: "Please wait for others to join.",
                                                      message: "Trying to play Blackjack by yourself?",
                                                      preferredStyle: .alert)
                    alertView.addAction(UIAlertAction(title: "OK",
                                                      style: .default,
                                                      handler: { (_) in
                                                        alertView.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alertView, animated: true, completion: nil)
                    
                    return false
                }
                else if !allPlayersReady() {
                    if connectivityType == "host" {
                        let alertView = UIAlertController(title: "Unable To Start Game",
                                                          message: "Not all players are ready.",
                                                          preferredStyle: .alert)
                        alertView.addAction(UIAlertAction(title: "OK",
                                                          style: .default,
                                                          handler: { (_) in
                                                            alertView.dismiss(animated: true, completion: nil)
                        }))
                        self.present(alertView, animated: true, completion: nil)
                    }
                    
                    return false
                }
            }
        }
        return true
    }
    
    func allPlayersReady() -> Bool {
        var result = true
        for player in appDelegate.players {
            if !player.isReady {
                result = false
                break
            }
        }
        
        return result
    }
    
    func playerReadyStyle(isReady: Bool) {
        if isReady {
            bCancel.isHidden = false
            bReady.isHidden = true
            bAdjustBalance.isEnabled = false
            bAdjustBalance.backgroundColor = Colours.disabledRed
        }
        else {
            bCancel.isHidden = true
            bReady.isHidden = false
            bAdjustBalance.isEnabled = true
            bAdjustBalance.backgroundColor = Colours.primaryRed
        }
    }
        
    func hostRoom() {
        appDelegate.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: appDelegate.peerID, discoveryInfo: nil, serviceType: "bb-rm")
        appDelegate.nearbyServiceAdvertiser.delegate = self
        appDelegate.nearbyServiceAdvertiser.startAdvertisingPeer()
        print("Room now discoverable!")
    }
    
    func joinRoom() {
        let mcBrowser = MCBrowserViewController(serviceType: "bb-rm", session: appDelegate.mcSession)
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
                appDelegate.players = currentPlayers
                
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
            
        case "rejoin":
            if connectivityType == "connected" {
                do {
                    let currentPlayers = try JSONDecoder().decode([Player].self, from: bbMsg.data!)
                    appDelegate.players = currentPlayers
                    let messages = bbMsg.message!.split(separator: ":")
                    rejoinPhase = String(messages[0])
                    
                    if messages.count > 1 {
                        betCountdown = Int(messages[1])
                    }
                } catch {
                    fatalError("Unable to process the received data.")
                }
            }
            
        default:
            print("Lobby.swift: Unrecognised message [\(msgType)]")
        }
    }
    
    func addPlayer(newPlayer: Player) {
        appDelegate.players.append(newPlayer)
    }
    
    func adjustPlayerBalance(newBal: Double) {
        let playerIndex = appDelegate.getPlayerIndex()
        appDelegate.players[playerIndex].initialBalance = newBal
    }
    
    func sendJoinMessage() {
        if connectivityType == "connected" {
            do {
                let player = playerController.getCurrentPlayer()
                let playerData = try JSONEncoder().encode(player)
                let bbMessage = BBMessage(messageType: "join", message: nil, data: playerData)
                let messageData = try JSONEncoder().encode(bbMessage)
                
                try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
            } catch {
                fatalError("Unable to encode player details.")
            }
        }
    }
    
    func sendCurrentPlayers() {
        do {
            let currentPlayersData = try JSONEncoder().encode(appDelegate.players)
            let bbMessage = BBMessage(messageType: "current-players", message: nil, data: currentPlayersData)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
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
        self.dismiss(animated: true, completion: nil)
    }
}

extension LobbyViewController : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, appDelegate.mcSession)
    }
}

extension LobbyViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LobbyPlayerTableViewCell") as! LobbyPlayerTableViewCell
        
        let player = appDelegate.players[indexPath.row]
        cell.lblPlayerName.text = player.name
        cell.lblPlayerTitle.text = player.title
        if player.profilePicture != nil {
            //cell.ivPlayerProfilePicture.image = player.profilePicture
            
        }
        cell.changeReadyStatus(isReady: player.isReady)
        cell.lblStartingBalance.text = "$\(String(format: "%.2f", player.initialBalance!))"
        
        return cell
    }
}

class LobbyPlayerTableViewCell : UITableViewCell {
    
    @IBOutlet weak var ivPlayerProfilePicture: UIImageView!
    @IBOutlet weak var ivCheckmark: UIImageView!
    @IBOutlet weak var lblPlayerName: UILabel!
    @IBOutlet weak var lblPlayerTitle: UILabel!
    @IBOutlet weak var lblStartingBalance: UILabel!
    
    func changeReadyStatus(isReady: Bool) {
        if isReady {
            self.ivPlayerProfilePicture.layer.opacity = 50
            ivCheckmark.isHidden = false
        }
        else {
            ivCheckmark.isHidden = true
            self.ivPlayerProfilePicture.layer.opacity = 100
        }
    }
}
