//
//  ViewController.swift
//  YunaFirstApp
//
//  Created by USER on 2017. 7. 13..
//  Copyright © 2017년 Yuna Seol. All rights reserved.
//

import UIKit
import CoreMotion
import MultipeerConnectivity

class Game {
    var cardSet = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
    var myChips = 30
    var yourChips = 30
    var myBet = 0
    var yourBet = 0
    var meFirst = true
    var newSet = true
    var myCard: Int!
    var yourCard: Int!
    var next: Int?
    
    func pickMyCard() -> Int {
        let index = Int(arc4random_uniform(UInt32(cardSet.count)))
        self.myCard = cardSet.remove(at: index)
        if (cardSet.count == 0) {            //new card deck
            cardSet = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
        }
        return self.myCard
    }
    
    func pickYourCard(n: Int) {
        cardSet.removeFirst(n)
        self.yourCard = n
        if (cardSet.count == 0) {            //new card deck
            cardSet = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
        }
    }
    
    func myTurn(n: Int) -> Bool? {
        newSet = false
        if (n == 0 ) {          // die
            myChips -= myBet
            yourChips += (myBet + yourBet)
            if (myCard == 10) {
                yourChips += 10
                myChips -= 10
            }
            meFirst = false
            newSet = true
        } else if ( n > yourBet - myBet) {  // more bet
            myChips -= n
            myBet += n
        } else if ( myCard > yourCard) {    // Card open (win)
            myChips += (myBet + yourBet)
            yourChips -= (myBet + yourBet)
            meFirst = true
            newSet = true
        } else if ( myCard == yourCard) {   //          (draw)
            // next Stage
            newSet = true
        } else if ( myCard < yourCard) {    //          (loose)
            myChips -= (myBet + yourBet)
            yourChips += (myBet + yourBet)
            meFirst = false
            newSet = true
        }
        
        // Game Over
        if (yourChips == 0) {
            return true
        } else if (myChips == 0) {
            return false
        }
        return nil
    }
    
    func yourTurn(n: Int) -> Bool? {
        newSet = false
        if (n == 0 ) {          // die
            myChips += myBet
            yourChips -= (myBet + yourBet)
            if (yourCard == 10) {
                myChips += 10
                yourChips -= 10
            }
            meFirst = true
            newSet = true
        } else if ( n > yourBet - myBet) {  // more bet
            yourChips -= n
            yourBet += n
        } else if ( myCard > yourCard) {    // Card open (win)
            myChips += (myBet + yourBet)
            yourChips -= (myBet + yourBet)
            meFirst = true
            newSet = true
        } else if ( myCard == yourCard) {   //           (draw)
            // next Stage
            newSet = true
        } else if ( myCard < yourCard) {    //           (loose)
            myChips -= (myBet + yourBet)
            yourChips += (myBet + yourBet)
            meFirst = false
            newSet = true
        }
        
        
        // Game Over
        if (yourChips == 0) {
            return true
        } else if (myChips == 0) {
            return false
        }
        return nil
    }
    
    
}

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate, UITextFieldDelegate {
    
    let serviceType = "Indian-Poker"
    
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    var session: MCSession!
    var peerID: MCPeerID!
    
    var cntTouch = 0
    let game = Game()

    @IBOutlet weak var gameResult: UILabel!
    @IBOutlet weak var touchCnt: UILabel!
    @IBOutlet weak var cardView: UIImageView!
    @IBOutlet weak var leftCards: UILabel!
    @IBOutlet weak var chipImageView1: UIImageView!
    @IBOutlet weak var chipImageView2: UIImageView!
    @IBOutlet weak var betImageView1: UIImageView!
    @IBOutlet weak var betImageView2: UIImageView!

    @IBOutlet weak var chipsLabel1: UILabel!
    @IBOutlet weak var chipsLabel2: UILabel!
    @IBOutlet weak var betLabel1: UILabel!
    @IBOutlet weak var betLabel2: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        chipImageView1.image = UIImage(named: "chips.png")
        chipImageView2.image = UIImage(named: "chips.png")
        betImageView1.image = UIImage(named: "chip1.png")
        betImageView2.image = UIImage(named: "chip1.png")
        chipsLabel1.text = "30"
        chipsLabel2.text = "30"
        betLabel1.text = "0"
        betLabel2.text = "0"
        
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        // 고유서비스명을 가진 브라우저 VC생성
        self.browser = MCBrowserViewController(serviceType: serviceType, session: self.session)
        self.browser.delegate = self
        self.assistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: self.session)
        // 채팅 시작을
        self.assistant.start()
        
        var chooseFirst = 200 + Int(arc4random_uniform(UInt32(10)))
        
        let data = NSData(bytes: &chooseFirst, length: MemoryLayout<NSInteger>.size)
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        
        let currentCard = UIImage(named: "card\(chooseFirst).png")
        self.cardView.image = currentCard
        //leftCards.text = numset.description
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        cntTouch += 1
        leftCards.text = cntTouch.description
    }
    
    
    @IBAction func shakeButton(_ sender: Any) {
        game.myTurn(n: cntTouch)
        var tempCntTouch = cntTouch + 100
        let data = NSData(bytes: &tempCntTouch, length: MemoryLayout<NSInteger>.size)
        
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        
       
        
    }
    
    @IBAction func cardChangeButton(_ sender: Any) {
        
        var number = Int(arc4random_uniform(UInt32(10)))
        
        let data = NSData(bytes: &index, length: MemoryLayout<NSInteger>.size)
        
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        
        let cardNum = numset.remove(at: index)
        let currentCard = UIImage(named: "card\(cardNum).png")
        self.cardView.image = currentCard
        //leftCards.text = numset.description
    }
    
    func updateCard(index: Int, fromPeer peerID: MCPeerID) {

        let currentCard = UIImage(named: "card\(cardNum).png")
        self.cardView.image = currentCard
        //leftCards.text = numset.description
    }
    
    @IBAction func browserBtnTab(_ sender: Any) {
        self.present(self.browser, animated: true, completion: nil)
    }
    
    func browserViewControllerDidFinish(
        _ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is dismissed (ie the Done button was tapped)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(
        _ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is cancelled
        
        self.dismiss(animated: true, completion: nil)
    }

    
    // 상대에게 NDData가 보내져왔을때
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID)  {
        DispatchQueue.main.async() {
            let data = NSData(data: data)
            var u2num : NSInteger = 0
            data.getBytes(&u2num, length: data.length)
            if (u2num >= 100) {
                let temp = u2num - 100
                self.game.yourTurn(n: temp)
            }
            // 카드 업데이트
            // self.updateCard(index: u2num, fromPeer: peerID)
        }
    }

    
    // The following methods do nothing, but the MCSessionDelegate protocol
    // requires that we implement them.
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress)  {
        
        // Called when a peer starts sending a file to us
    }
    
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL, withError error: Error?)  {
        // Called when a file has finished transferring from another peer
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream,
                 withName streamName: String, fromPeer peerID: MCPeerID)  {
        // Called when a peer establishes a stream with us
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID,
                 didChange state: MCSessionState)  {
        // Called when a connected peer changes state (for example, goes offline)
        
    }

}

