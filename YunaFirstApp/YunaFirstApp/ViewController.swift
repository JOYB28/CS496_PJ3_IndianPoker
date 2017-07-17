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
    var setWin = false

    // pickCard : 현재의 카드셋에서 카드를 하나 뽑아 그 숫자를 리턴한다.
    func pickCard() -> Int {
        let index = Int(arc4random_uniform(UInt32(cardSet.count)))
        myCard = cardSet.remove(at: index)
        if (cardSet.count == 0) {            //new card deck
            cardSet = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
        }
        return myCard
    }
    
    // myTurn : 현재의 mybet, yourbet으로 자신의 차례를 진행한다.
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
            setWin = true

        } else if ( myCard == yourCard) {   //          (draw)
            // next Stage
            newSet = true
            setWin = true
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
    
    // myTurn : 현재의 mybet, yourbet으로 자신의 차례를 진행한다.
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
            setWin = true
            
            meFirst = true
            newSet = true
        } else if ( yourBet > myBet) {  // more bet
        } else if ( myCard > yourCard) {    // Card open (win)
            myChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            meFirst = true
            newSet = true
            setWin = true
        } else if ( myCard == yourCard) {   //           (draw)
            // next Stage
            newSet = true
            setWin = true
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
    }
    
    // 상대에게 NSData가 보내져왔을때
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID)  {
        DispatchQueue.main.async() {
            let data = NSData(data: data)
            var u2num : NSInteger = 0
            data.getBytes(&u2num, length: data.length)
            
            // 상대가 버튼을 눌러서 상대가 선이고, 내가 후일때
            if (u2num == 200) {
                self.game.meFirst = false
                self.game.myturn = false
                self.whoseTurn.text = "Your turn"
                self.game.setWin = false
                self.game.myBet += 1
                self.game.yourBet += 1
                self.game.myChips -= 1
                self.game.yourChips -= 1
                self.updateBetAndChips()
                
            }
            // 상대방 배팅이 끝났을 때
            else if (u2num == 100) {
                self.gameResult.text = self.game.yourTurn()?.description
                self.game.myturn = true
                self.whoseTurn.text = "My turn"
                self.chipsLabel1.text = self.game.myChips.description
                self.chipsLabel2.text = self.game.yourChips.description
                self.betLabel1.text = self.game.myBet.description
                self.betLabel2.text = self.game.yourBet.description
                // 게임을 이긴사람이 카드를 각각 뽑아 전송하기
                if (self.game.setWin == true){
                    self.pickMineAndYours()
                }
            }
            // 상대가 배팅을 하나씩 했을 때
            else if (u2num == 101) {
                self.game.yourBet += 1
                self.game.yourChips -= 1
                self.betLabel2.text = self.game.yourBet.description
                self.chipsLabel2.text = self.game.yourChips.description
            }
            // 내 카드 숫자가 올때 (11~20)
            else if (u2num > 10) {
                self.game.myCard = u2num - 10
                let currentCard = UIImage(named: "card\(self.game.myCard).png")
                self.cardView.image = currentCard
                if let index = self.game.cardSet.index(of : self.game.myCard){
                    self.game.cardSet.remove(at: index)
                }
            }
            // 상대 카드 정보가 올때 (1~10)
            else if (u2num > 0) {
                self.game.yourCard = u2num
                if let index = self.game.cardSet.index(of : self.game.myCard){
                    self.game.cardSet.remove(at: index)
                }
            }
        }
    }
    
    //카드를 각각 뽑아 전송하기 함수
    func pickMineAndYours() {
        var myNewCard = self.game.pickCard()
        let yourNewCard = self.game.pickCard()
        var temp = yourNewCard + 10
        let data1 = NSData(bytes: &myNewCard, length: MemoryLayout<NSInteger>.size)
        do {
            try self.session.send(data1 as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        let data2 = NSData(bytes: &temp, length: MemoryLayout<NSInteger>.size)
        do {
            try self.session.send(data2 as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        self.game.setWin = false
        self.game.myCard = myNewCard
        self.game.yourCard = yourNewCard
        
        let currentCard = UIImage(named: "card\(myNewCard).png")
        self.cardView.image = currentCard
    }
    
    @IBAction func chooseFirstTurn(_ sender: Any) {
        // 200을 보냄. 내가 선이고, 상대가 후가 됨
        var tempMypick = 200
        let data = NSData(bytes: &tempMypick, length: MemoryLayout<NSInteger>.size)
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
 
        self.game.meFirst = true
        self.game.myturn = true
        self.whoseTurn.text = "My turn"
        
        //2초후 게임 시작을 위해 카드를 각각 뽑음
        sleep(2)
        pickMineAndYours()
        //기본 배팅으로 1개씩 진행
        game.myBet += 1
        game.yourBet += 1
        game.myChips -= 1
        game.yourChips -= 1
        self.updateBetAndChips()
        

    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (game.myturn == true && (self.game.myBet - self.game.yourBet < self.game.yourChips)){
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
    
    // 자신의 배팅이 종료되었음을 의미
    @IBAction func shakeButton(_ sender: Any) {
        self.gameResult.text = self.game.myTurn()?.description
        updateBetAndChips()
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
        
        
        // 게임을 이긴사람이 카드를 각각 뽑아 전송하기
        if (game.setWin == true){
            self.pickMineAndYours()
        }
    }
    
    @IBAction func browserBtnTab(_ sender: Any) {
        self.present(self.browser, animated: true, completion: nil)
    }
    
    // 초록색의 숫자를 update, bet과 chips
    func updateBetAndChips() {
        betLabel1.text = self.game.myBet.description
        betLabel2.text = self.game.yourBet.description
        chipsLabel1.text = self.game.myChips.description
        chipsLabel2.text = self.game.yourChips.description
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

