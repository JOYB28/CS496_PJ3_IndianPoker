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
    var myturn = true
    var newSet = true
    var myCard = 1
    var yourCard = 1
    
    func pickMyCard() -> Int {
        let index = Int(arc4random_uniform(UInt32(cardSet.count)))
        myCard = cardSet.remove(at: index)
        if (cardSet.count == 0) {            //new card deck
            cardSet = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
        }
        return myCard
    }
    

    func pickYourCard(n: Int) {
        cardSet.removeFirst(n)
        self.yourCard = n
        if (cardSet.count == 0) {            //new card deck
            cardSet = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
        }
    }
    
    func myTurn() -> Bool? {
        newSet = false
        if (myBet < yourBet) {          // die
            yourChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            if (myCard == 10) {
                yourChips += 10
                myChips -= 10
            }
            meFirst = false
            newSet = true
        } else if (myBet > yourBet) {  // more bet
        } else if ( myCard > yourCard) {    // Card open (win)
            myChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            meFirst = true
            newSet = true
        } else if ( myCard == yourCard) {   //          (draw)
            // next Stage
            newSet = true
        } else if ( myCard < yourCard) {    //          (loose)
            yourChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
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
    
    func yourTurn() -> Bool? {
        newSet = false
        if (yourBet < myBet) {          // die
            myChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            if (yourCard == 10) {
                myChips += 10
                yourChips -= 10
            }
            
            meFirst = true
            newSet = true
        } else if ( yourBet > myBet) {  // more bet
        } else if ( myCard > yourCard) {    // Card open (win)
            myChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            meFirst = true
            newSet = true
        } else if ( myCard == yourCard) {   //           (draw)
            // next Stage
            newSet = true
        } else if ( myCard < yourCard) {    //           (loose)
            yourChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
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
    var mypick = 1
    let game = Game()

    @IBOutlet weak var whoseTurn: UILabel!
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
        
        pickMypick()

    }
    
    // 상대에게 NDData가 보내져왔을때
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID)  {
        DispatchQueue.main.async() {
            let data = NSData(data: data)
            var u2num : NSInteger = 0
            data.getBytes(&u2num, length: data.length)
            
            // 선 정할때 상대꺼랑 비교
            if (u2num >= 200) {
                if (u2num < self.mypick+200) {
                    self.game.meFirst = true
                    self.game.myturn = true
                    self.whoseTurn.text = "My turn"
                } else if (u2num > self.mypick+200) {
                    self.game.meFirst = false
                    self.game.myturn = false
                    self.whoseTurn.text = "Your turn"
                } else {
                    self.pickMypick()
                }
            }
            // 상대방 배팅이 끝났을 때
            else if (u2num == 100) {
                self.game.yourTurn()
                self.chipsLabel2.text = self.game.yourChips.description
                self.game.myturn = true
                self.whoseTurn.text = "My turn"
                self.game.yourBet = 0
            }
            // 상대가 배팅을 하나씩 했을 때
            else if (u2num == 101) {
                self.game.yourBet += 1
                self.game.yourChips -= 1
                self.betLabel2.text = self.game.yourBet.description
                self.chipsLabel2.text = self.game.yourChips.description
            }
            // 카드 업데이트
            // self.updateCard(index: u2num, fromPeer: peerID)
        }
    }
    
    // 선 정할때 내카드 뽑기
    func pickMypick() {
        mypick = Int(arc4random_uniform(UInt32(10))) + 1
        var tempMypick = 200 + mypick
        
        let data = NSData(bytes: &tempMypick, length: MemoryLayout<NSInteger>.size)
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        
        let currentCard = UIImage(named: "card\(mypick).png")
        self.cardView.image = currentCard
        //leftCards.text = numset.description
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (game.myturn == true){
            cntTouch += 1
            self.game.myBet += 1
            self.game.myChips -= 1
            betLabel1.text = self.game.myBet.description
            chipsLabel1.text = self.game.myChips.description
            touchCnt.text = cntTouch.description
            var tempCntTouch = 101
            let data = NSData(bytes: &tempCntTouch, length: MemoryLayout<NSInteger>.size)
            do {
                try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            } catch {
                print(error)
            }
        }
    }
    
    // My betting
    @IBAction func shakeButton(_ sender: Any) {
        game.myTurn()
        var betOver = 100
        let data = NSData(bytes: &betOver, length: MemoryLayout<NSInteger>.size)
        
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        game.myturn = false
        whoseTurn.text = "your turn"
        cntTouch = 0
        touchCnt.text = cntTouch.description
    }
    
    @IBAction func cardChangeButton(_ sender: Any) {
        
        var index = Int(arc4random_uniform(UInt32(10)))
        
        let data = NSData(bytes: &index, length: MemoryLayout<NSInteger>.size)
        
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        
//        let cardNum = numset.remove(at: index)
//        let currentCard = UIImage(named: "card\(cardNum).png")
//        self.cardView.image = currentCard
        //leftCards.text = numset.description
    }
    
    func updateCard(index: Int, fromPeer peerID: MCPeerID) {

//        let currentCard = UIImage(named: "card\(cardNum).png")
//        self.cardView.image = currentCard
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

