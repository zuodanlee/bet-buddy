//
//  ViewController.swift
//  Bet Buddy
//
//  Created by Jordan Lee on 23/1/21.
//

import UIKit

class ViewController: UIViewController {
    //var gamemodeController = GamemodeController()
    var gamemodes: [Gamemode] = []
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let cellSpacingHeight: CGFloat = 10
    @IBOutlet weak var svAvailable: UIStackView!
    @IBOutlet weak var tvGamemodes: UITableView!
    @IBOutlet weak var svAvailableHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        gamemodes = createGamemodes()
        tvGamemodes.isScrollEnabled = false
        
        // Design
        svAvailable.backgroundColor = Colours.primaryRed
        svAvailable.layer.cornerRadius = 8
        
        tvGamemodes.backgroundColor = Colours.transparent
        tvGamemodes.layer.cornerRadius = 8
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var frame: CGRect = tvGamemodes.frame
        frame.size.height = tvGamemodes.contentSize.height
        tvGamemodes.frame = frame
        
        svAvailableHeightConstraint.constant = tvGamemodes.contentSize.height + 71
    }

    func createGamemodes() -> [Gamemode] {
        
        var tempGamemodes: [Gamemode] = []
        
        let gamemode1 = Gamemode(image: UIImage(named: "bj_banner")!, name: "BLACKJACK")
        let gamemode2 = Gamemode(image: UIImage(named: "mj_banner")!, name: "MAHJONG")
        let gamemode3 = Gamemode(image: UIImage(named: "poker_banner")!, name: "POKER")
        
        tempGamemodes.append(gamemode1)
        tempGamemodes.append(gamemode2)
        tempGamemodes.append(gamemode3)
        
        return tempGamemodes
    }
    
    
    @IBAction func createRoom(_ sender: Any) {
        let storyboard = UIStoryboard(name: "CreateRoomBJ", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CreateRoomBJ") as UIViewController
        vc.modalPresentationStyle = .fullScreen // try without fullscreen
        present(vc, animated: true, completion: nil)
    }
}

extension ViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return gamemodes.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GamemodeCell") as! GamemodeTableViewCell
        
        //let gamemode = gamemodeController.retrieveAllGamemodes()[indexPath.row]
        //cell.lblGamemodeName.text = gamemode.name
        //cell.ivGamemodeGraphic.image = UIImage(data: gamemode.graphic!)
        
        let gamemode = gamemodes[indexPath.section]
        cell.layer.cornerRadius = 8
        cell.setGamemode(gamemode: gamemode)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // this will turn on `masksToBounds` just before showing the cell
        cell.contentView.layer.masksToBounds = true
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = Colours.primaryRed
    }
}

class GamemodeTableViewCell : UITableViewCell {
    @IBOutlet weak var vGamemodeCover: UIView!
    @IBOutlet weak var lblGamemodeName: UILabel!
    @IBOutlet weak var ivGamemodeGraphic: UIImageView!
    
    @IBOutlet weak var vGamemodeActions: UIView!
    @IBOutlet weak var bCreateRoom: UIButton!
    @IBOutlet weak var bJoinRoom: UIButton!
    
    var isFlipped = false
    
    @IBAction func flipAction(_ sender: Any) {
        guard let displayView = isFlipped ? vGamemodeActions : vGamemodeCover else { return }
        UIView.transition(with: contentView, duration: 0.3,
                            options: isFlipped ? .transitionFlipFromRight: .transitionFlipFromLeft,
                            animations: { () -> Void in
                                self.contentView.insertSubview(displayView, at: 0)
                            }, completion: nil)
        
        isFlipped = !isFlipped
    }
    
    func setGamemode(gamemode: Gamemode) {
        self.backgroundColor = Colours.primaryRed
        
        lblGamemodeName.text = gamemode.name
        lblGamemodeName.textColor = Colours.white
        lblGamemodeName.font = UIFont(name: "NTR", size: 25)
        ivGamemodeGraphic.image = gamemode.graphic
        ivGamemodeGraphic.backgroundColor = Colours.tintRed
        
        vGamemodeActions.backgroundColor = Colours.tintRed
        vGamemodeActions.layer.cornerRadius = 8
    }
}
