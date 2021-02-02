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
    @IBOutlet weak var bEndRound: UIButton!
    @IBOutlet weak var bEndGame: UIButton!
    @IBOutlet weak var svHostBottomControls: UIStackView!
    @IBOutlet weak var bPlaceBet: UIButton!
    @IBOutlet weak var lblPhase: UILabel!
    @IBAction func placeBet(_ sender: Any) {
        
        if connectivityType == "connected" {
            alertView = UIAlertController(title: "Place Bet",
                                              message: "Please enter the bet amount.",
                                              preferredStyle: .alert)
            alertView.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "1"
            }
            alertView.addAction(UIAlertAction(title: "Cancel",
                                              style: .cancel,
                                              handler: { (_) in
                                                self.alertView.dismiss(animated: true, completion: nil)
            }))
            alertView.addAction(UIAlertAction(title: "Confirm",
                                              style: .default,
                                              handler: { (_) in
                                                let rawInput = self.alertView.textFields![0].text!
                                                let roundBet = Double(rawInput)
                                                if roundBet != nil {
                                                    let player = self.players[self.playerID]
                                                    if roundBet! > player.balance! {
                                                        self.alertView.message = "Insufficient balance!"
                                                        self.present(self.alertView, animated: true, completion: nil)
                                                    }
                                                    else {
                                                        self.players[self.playerID].roundBet = roundBet
                                                        self.sendBetChange()
                                                        self.loadPlayers()
                                                    }
                                                }
                                                else {
                                                    self.alertView.message = "'\(rawInput)' is not a number."
                                                    self.present(self.alertView, animated: true, completion: nil)
                                                }
            }))
            self.present(alertView, animated: true, completion: nil)
        }
    }
    @IBAction func endRound(_ sender: Any) {
        let outcomes = generateOutcomes()
        payout(outcomes: outcomes)
        loadPlayers()
        
        lblPhase.text = "Payout Phase"
        sendPayoutPhase()
        
        bEndGame.isEnabled = true
        bEndGame.backgroundColor = Colours.primaryRed
        bEndRound.isHidden = true
        bStartRound.isHidden = false
    }
    @IBAction func startRound(_ sender: Any) {
        
        if connectivityType == "host" {
            // allow banker to end the round and hide start round
            bEndRound.isHidden = false
            bStartRound.isHidden = true
            
            startBettingPhase()
        }
    }
    @IBAction func endGame(_ sender: Any) {
        sendEndGame()
    }
    
    var connectivityType = "none"
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var players: [Player] = []
    var playerID: Int!
    var numConnectedPlayers = 1
    var timer: Timer!
    var countdown: Int!
    let startingAmt: Double = 50
    var player: Player!
    var isInitialLoad = true
    var alertView: UIAlertController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tvPlayers.delegate = self
        tvPlayers.dataSource = self
        
        loadPlayers()
        setupConnectivity()
        additionalStyling()
        initialControlsManipulation()
        
        //timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
        // report arrival to host
        if connectivityType == "connected" {
            sendArrived()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if connectivityType == "host" {
            let cell = tvPlayers.cellForRow(at: IndexPath(row: 0, section: 0)) as! BlackjackPlayerTableViewCell
            cell.scOutcome.isEnabled = false
            cell.scMultiplier.isEnabled = false
        }
    }
    
    func additionalStyling() {
        
        let styleHelper = StyleHelper()
        
        // colour
        bStartRound.backgroundColor = Colours.primaryRed
        bEndRound.backgroundColor = Colours.primaryRed
        bEndGame.backgroundColor = Colours.primaryRed
        bPlaceBet.backgroundColor = Colours.primaryRed
        
        // rounded corners
        styleHelper.roundCorners(views: [bStartRound, bEndRound, bEndGame, bPlaceBet])
    }
    
    func hideControls() {
        if connectivityType != "host" {
            svHostBottomControls.isHidden = true
        }
        else {
            bPlaceBet.isHidden = true
            bStartRound.isHidden = true
        }
    }
    
    func initialControlsManipulation() {
        hideControls()
        
        if connectivityType == "host" {
            bEndRound.isEnabled = false
            bEndGame.isEnabled = false
            
            bEndRound.backgroundColor = Colours.disabledRed
            bEndGame.backgroundColor = Colours.disabledRed
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.destination is HomeViewController
        {
            let vc = segue.destination as! HomeViewController
            vc.mcSession = self.mcSession
        }
    }
    
    func setupConnectivity() {
        mcSession.delegate = self
    }
    
    func loadPlayers() {
        if isInitialLoad {
            for i in 0...players.count-1 {
                players[i].playerID = players.count-1
                players[i].balance = startingAmt
                players[i].roundBet = 0
            }
            
            player = players[playerID]
            isInitialLoad = false
        }
        
        DispatchQueue.main.async {
            self.tvPlayers.reloadData()
        }
    }
    
    @objc func updateBetTimer() {
        print(countdown!)
        if countdown > 0 {
            lblPhase.text = "Betting Phase: \(String(countdown))"
            countdown -= 1
        }
        else if countdown == 0 {
            timer.invalidate()
            bEndRound.isEnabled = true // allow banker to start the round
            bEndRound.backgroundColor = Colours.primaryRed
            
            bPlaceBet.isEnabled = false // stop players from changing bets
            bPlaceBet.backgroundColor = Colours.disabledRed
            
            if connectivityType == "host" {
                sendPlayPhase()
                lblPhase.text = "Play Phase"
            }
            else {
                if alertView != nil {
                    alertView.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func startBettingPhase() {
        sendBettingPhase()
        startAsyncTimer(phase: "bet")
        bEndRound.backgroundColor = Colours.disabledRed
    }
    
    func generateOutcomes() -> [BlackjackOutcome] {
        var outcomes: [BlackjackOutcome] = []
        for i in 0...players.count-1 {
            let cell = tvPlayers.cellForRow(at: IndexPath(row: i, section: 0)) as! BlackjackPlayerTableViewCell
            let player = players[i]
            
            var didBankerWin = true
            if cell.scOutcome.selectedSegmentIndex == 1 {
                didBankerWin = false
            }
            
            var multiplier = 1
            if cell.scMultiplier.selectedSegmentIndex == 1 {
                multiplier = 2
            }
            else if cell.scMultiplier.selectedSegmentIndex == 2 {
                multiplier = 3
            }
            else if cell.scMultiplier.selectedSegmentIndex == 3 {
                multiplier = 7
            }
            
            var newOutcome = BlackjackOutcome(playerID: player.playerID!, roundBet: player.roundBet!, didBankerWin: didBankerWin, multiplier: multiplier)
            
            newOutcome.payout = newOutcome.calculatePayout()
            
            outcomes.append(newOutcome)
        }
        
        return outcomes
    }
    
    func payout(outcomes: [BlackjackOutcome]) {
        for i in 1...players.count-1 {
            players[i].balance! += outcomes[i].payout!
            players[0].balance! -= outcomes[i].payout!
        }
    }
    
    func processMessage(bbMsg: BBMessage) {
        let msgType = bbMsg.messageType
        
        switch msgType {
        case "arrived-blackjack":
            if connectivityType == "host" {
                numConnectedPlayers += 1
                if numConnectedPlayers == players.count {
                    startBettingPhase()
                }
            }
            
        case "phase-bet":
            if connectivityType == "connected" {
                countdown = Int(bbMsg.message!) // time in seconds
                startAsyncTimer(phase: "bet")
                DispatchQueue.main.async {
                    self.bPlaceBet.isEnabled = true
                    self.bPlaceBet.backgroundColor = Colours.primaryRed
                }
            }
            
        case "bet-change":
            do {
                let currentPlayers = try JSONDecoder().decode([Player].self, from: bbMsg.data!)
                players = currentPlayers
                
                loadPlayers()
            } catch {
                fatalError("Unable to process the received data.")
            }
            
        case "phase-play":
            DispatchQueue.main.async {
                self.lblPhase.text = "Play Phase"
            }
            
        case "phase-payout":
            do {
                let currentPlayers = try JSONDecoder().decode([Player].self, from: bbMsg.data!)
                players = currentPlayers
                
                DispatchQueue.main.async {
                    self.lblPhase.text = "Payout Phase"
                }
                
                loadPlayers()
            } catch {
                fatalError("Unable to process the received data.")
            }
            
        case "end-game":
            if connectivityType == "connected" {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "endBlackjack", sender: self)
                }
            }
            
        default:
            print("Blackjack.swift: Unrecognised message: [\(msgType)]")
        }
    }
    
    func sendArrived() {
        do {
            print("Sending arrival message...")
            let bbMessage = BBMessage(messageType: "arrived-blackjack", message: nil, data: nil)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? mcSession.send(messageData, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendBettingPhase() {
        do {
            countdown = 15
            let bbMessage = BBMessage(messageType: "phase-bet", message: String(countdown), data: nil)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? mcSession.send(messageData, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendBetChange() {
        do {
            let currentPlayersData = try JSONEncoder().encode(players)
            let bbMessage = BBMessage(messageType: "bet-change", message: nil, data: currentPlayersData)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? mcSession.send(messageData, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendPlayPhase() {
        do {
            let bbMessage = BBMessage(messageType: "phase-play", message: nil, data: nil)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? mcSession.send(messageData, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendPayoutPhase() {
        do {
            let currentPlayersData = try JSONEncoder().encode(players)
            let bbMessage = BBMessage(messageType: "phase-payout", message: nil, data: currentPlayersData)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? mcSession.send(messageData, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendEndGame() {
        do {
            let bbMessage = BBMessage(messageType: "end-game", message: nil, data: nil)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? mcSession.send(messageData, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func startAsyncTimer(phase: String) {
        DispatchQueue.main.async {
            if phase == "bet" {
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateBetTimer), userInfo: nil, repeats: true)
            }
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
        cell.lblBalance.text = "Balance: $\(player.balance!)"
        cell.lblRoundBet.text = "Round Bet: $\(player.roundBet!)"
        cell.scOutcome.selectedSegmentIndex = 0
        cell.scMultiplier.selectedSegmentIndex = 0
        cell.selectionStyle = .none
        if indexPath.row != 0 {
            cell.svHostBanner.isHidden = true
        }
        else {
            cell.svHostBanner.backgroundColor = Colours.tintRed
            cell.svHostBanner.layer.cornerRadius = 8
        }
        
        if connectivityType != "host" {
            cell.scOutcome.isEnabled = false
            cell.scMultiplier.isEnabled = false
        }
        
        return cell
    }
}

class BlackjackPlayerTableViewCell : UITableViewCell {
    
    @IBOutlet weak var lblPlayerName: UILabel!
    @IBOutlet weak var lblPlayerTitle: UILabel!
    @IBOutlet weak var ivPlayerProfilePicture: UIImageView!
    @IBOutlet weak var lblBalance: UILabel!
    @IBOutlet weak var lblRoundBet: UILabel!
    @IBOutlet weak var scOutcome: UISegmentedControl!
    @IBOutlet weak var scMultiplier: UISegmentedControl!
    @IBOutlet weak var svHostBanner: UIStackView!
    
}
