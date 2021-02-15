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
                                                var roundBet = Double(rawInput)
                                                if roundBet != nil {
                                                    let player = self.appDelegate.players[self.appDelegate.getPlayerIndex()]
                                                    if roundBet! > player.balance! {
                                                        self.alertView.message = "Insufficient balance!"
                                                        self.present(self.alertView, animated: true, completion: nil)
                                                    }
                                                    else if roundBet! < 0 {
                                                        self.alertView.message = "Please enter a number more than 0."
                                                        self.present(self.alertView, animated: true, completion: nil)
                                                    }
                                                    else {
                                                        // valid input - proceed with bet change
                                                        roundBet = Double(String(format: "%.2f", roundBet!)) // round bet to 2dp
                                                        self.adjustRoundBet(newBet: roundBet!)
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
        payout()
        loadPlayers()
        
        lblPhase.text = "Payout Phase"
        phase = "payout"
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
        appDelegate.players = []
        sendEndGame()
        
        if appDelegate.nearbyServiceAdvertiser != nil {
            appDelegate.nearbyServiceAdvertiser.stopAdvertisingPeer()
        }
    }
    
    var connectivityType = "none"
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var playerID: String!
    var numConnectedPlayers = 1
    var timer: Timer!
    let countdownMax = 15
    var countdown: Int!
    var player: Player!
    var isInitialLoad = true
    var alertView: UIAlertController!
    var phase: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tvPlayers.delegate = self
        tvPlayers.dataSource = self
        
        initOutcomes()
        loadPlayers()
        setupConnectivity()
        additionalStyling()
        initialControlsManipulation()
        
        // report arrival to host
        if connectivityType == "connected" {
            if phase != nil {
                if phase == "bet" {
                    startAsyncTimer(phase: "bet")
                    DispatchQueue.main.async {
                        self.bPlaceBet.isEnabled = true
                        self.bPlaceBet.backgroundColor = Colours.primaryRed
                    }
                }
                else if phase == "play" {
                    lblPhase.text = "Play Phase"
                    startPlayPhase()
                }
                else if phase == "payout" {
                    lblPhase.text = "Payout Phase"
                    startPayoutPhase()
                }
            }
            else {
                sendArrived()
            }
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
            vc.mcSession = appDelegate.mcSession
        }
    }
    
    func setupConnectivity() {
        appDelegate.mcSession.delegate = self
    }
    
    func loadPlayers() {
        if isInitialLoad {
            if phase == nil {
                for i in 0...appDelegate.players.count-1 {
                    appDelegate.players[i].balance = appDelegate.players[i].initialBalance
                    appDelegate.players[i].roundBet = 0
                }
            }
            
            player = appDelegate.players[appDelegate.getPlayerIndex()]
            isInitialLoad = false
        }
        
        DispatchQueue.main.async {
            self.tvPlayers.reloadData()
        }
    }
    
    @objc func updateBetTimer() {
        if countdown > 0 {
            lblPhase.text = "Betting Phase: \(String(countdown))"
            sendUpdateTimer()
            countdown -= 1
        }
        else if countdown == 0 {
            startPlayPhase()
        }
    }
    
    func startBettingPhase() {
        countdown = countdownMax
        sendBettingPhase()
        phase = "bet"
        startAsyncTimer(phase: "bet")
        
        DispatchQueue.main.async {
            self.bEndRound.backgroundColor = Colours.disabledRed
        }
    }
    
    func startPlayPhase() {
        if timer != nil {
            timer.invalidate()
        }
        bEndRound.isEnabled = true // allow banker to end the round
        bEndRound.backgroundColor = Colours.primaryRed
        
        if connectivityType == "host" {
            sendPlayPhase()
            phase = "play"
            lblPhase.text = "Play Phase"
        }
        else {
            if alertView != nil {
                alertView.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func startPayoutPhase() {
        bPlaceBet.isEnabled = false // stop players from changing bets
        bPlaceBet.backgroundColor = Colours.disabledRed
    }
    
    func payout() {
        for i in 1...appDelegate.players.count-1 {
            player = appDelegate.players[i]
            player.calculatePayout()
            
            appDelegate.players[i].balance! += player.payout!
            appDelegate.players[0].balance! -= player.payout!
        }
    }
    
    func initOutcomes() {
        for i in 0...appDelegate.players.count-1 {
            appDelegate.players[i].outcomeIndex = 0
            appDelegate.players[i].multiplier = 1
        }
    }
    
    func adjustRoundBet(newBet: Double) {
        let playerIndex = appDelegate.getPlayerIndex()
        appDelegate.players[playerIndex].roundBet = newBet
    }
    
    func processMessage(bbMsg: BBMessage) {
        let msgType = bbMsg.messageType
        
        switch msgType {
        case "arrived-blackjack":
            if connectivityType == "host" {
                numConnectedPlayers += 1
                if numConnectedPlayers == appDelegate.players.count {
                    startBettingPhase()
                }
            }
            
        case "phase-bet":
            if connectivityType == "connected" {
                DispatchQueue.main.async {
                    self.bPlaceBet.isEnabled = true
                    self.bPlaceBet.backgroundColor = Colours.primaryRed
                }
            }
            
        case "bet-change":
            do {
                let currentPlayers = try JSONDecoder().decode([Player].self, from: bbMsg.data!)
                appDelegate.players = currentPlayers
                
                for player in appDelegate.players {
                    print(player)
                }
                
                loadPlayers()
            } catch {
                fatalError("Unable to process the received data.")
            }
            
        case "phase-play":
            if connectivityType == "connected" {
                DispatchQueue.main.async {
                    self.bPlaceBet.isEnabled = false // stop players from changing bets
                    self.bPlaceBet.backgroundColor = Colours.disabledRed
                    self.lblPhase.text = "Play Phase"
                }
            }
            
        case "phase-payout":
            do {
                let currentPlayers = try JSONDecoder().decode([Player].self, from: bbMsg.data!)
                appDelegate.players = currentPlayers
                
                DispatchQueue.main.async {
                    self.lblPhase.text = "Payout Phase"
                }
                
                loadPlayers()
            } catch {
                fatalError("Unable to process the received data.")
            }
            
        case "end-game":
            if connectivityType == "connected" {
                appDelegate.players = []
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "endBlackjack", sender: self)
                }
            }
            
        case "join":
            if connectivityType == "host" {
                do {
                    let newPlayer = try JSONDecoder().decode(Player.self, from: bbMsg.data!)
                    
                    if appDelegate.getPlayer(withPlayerID: newPlayer.playerID) != nil {
                        sendRejoin()
                    }
                } catch {
                    fatalError("Unable to process the received data.")
                }
            }
            
        case "update-timer":
            if connectivityType == "connected" {
                let countdownStr: String = bbMsg.message!
                DispatchQueue.main.async {
                    self.lblPhase.text = "Betting Phase: \(countdownStr)"
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
            
            try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendBettingPhase() {
        do {
            let bbMessage = BBMessage(messageType: "phase-bet", message: String(countdown), data: nil)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendBetChange() {
        do {
            let currentPlayersData = try JSONEncoder().encode(appDelegate.players)
            let bbMessage = BBMessage(messageType: "bet-change", message: nil, data: currentPlayersData)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendPlayPhase() {
        do {
            let bbMessage = BBMessage(messageType: "phase-play", message: nil, data: nil)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendPayoutPhase() {
        do {
            let currentPlayersData = try JSONEncoder().encode(appDelegate.players)
            let bbMessage = BBMessage(messageType: "phase-payout", message: nil, data: currentPlayersData)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendEndGame() {
        do {
            let bbMessage = BBMessage(messageType: "end-game", message: nil, data: nil)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendRejoin() {
        do {
            let currentPlayersData = try JSONEncoder().encode(appDelegate.players)
            let bbMessage = BBMessage(messageType: "rejoin", message: phase! + ":" + String(countdown), data: currentPlayersData)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
        } catch {
            fatalError("Unable to encode player details.")
        }
    }
    
    func sendUpdateTimer() {
        do {
            let bbMessage = BBMessage(messageType: "update-timer", message: String(countdown), data: nil)
            let messageData = try JSONEncoder().encode(bbMessage)
            
            try? appDelegate.mcSession.send(messageData, toPeers: appDelegate.mcSession.connectedPeers, with: .reliable)
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
        return appDelegate.players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlackjackPlayerTableViewCell") as! BlackjackPlayerTableViewCell
        
        let player = appDelegate.players[indexPath.row]
        cell.lblPlayerName.text = player.name
        cell.lblPlayerTitle.text = player.title
        if player.profilePicture != nil {
            //cell.ivPlayerProfilePicture.image = player.profilePicture
            
        }
        cell.lblBalance.text = "$\(String(format: "%.2f", player.balance!))"
        cell.lblRoundBet.text = "$\(String(format: "%.2f", player.roundBet!))"
        cell.scOutcome.selectedSegmentIndex = player.outcomeIndex!
        if player.multiplier == 1 {
            cell.scMultiplier.selectedSegmentIndex = 0
        }
        else if player.multiplier == 2 {
            cell.scMultiplier.selectedSegmentIndex = 1
        }
        else if player.multiplier == 3 {
            cell.scMultiplier.selectedSegmentIndex = 2
        }
        else if player.multiplier == 7 {
            cell.scMultiplier.selectedSegmentIndex = 3
        }
        cell.selectionStyle = .none
        if indexPath.row != 0 {
            cell.svHostBanner.isHidden = true
        }
        else {
            cell.svHostBanner.isHidden = false
            cell.svHostBanner.backgroundColor = Colours.tintRed
            cell.svHostBanner.layer.cornerRadius = 8
        }
        
        if connectivityType != "host" {
            cell.scOutcome.isEnabled = false
            cell.scMultiplier.isEnabled = false
        }
        cell.delegate = self
        
        return cell
    }
}

extension BlackjackViewController : BlackjackPlayerTableViewCellDelegate {
    
    func scChangeValue(cell: BlackjackPlayerTableViewCell) {
        let rowNum = self.tvPlayers.indexPath(for: cell)!.row
        appDelegate.players[rowNum].outcomeIndex = cell.scOutcome.selectedSegmentIndex
        
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
        appDelegate.players[rowNum].multiplier = multiplier
    }
}

protocol BlackjackPlayerTableViewCellDelegate: AnyObject {
    func scChangeValue(cell: BlackjackPlayerTableViewCell)
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
    
    weak var delegate: BlackjackPlayerTableViewCellDelegate?
    
    @IBAction func changeOutcome(_ sender: Any) {
        delegate?.scChangeValue(cell: self)
    }
    @IBAction func changeMultiplier(_ sender: Any) {
        delegate?.scChangeValue(cell: self)
    }
}
