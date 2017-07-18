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

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate, UITextFieldDelegate {
    
    let serviceType = "Indian-Poker"
    
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    var session: MCSession!
    var peerID: MCPeerID!
    
    var cntTouch = 0
    var mypick = 1
    let game = Game()

    @IBOutlet weak var chooseFirstButton: UIButton!
    @IBOutlet weak var startView: UIView!
    @IBOutlet weak var gameStartButton: UIButton!
    
    @IBOutlet weak var whoseTurn: UILabel!
    @IBOutlet weak var gameResult: UILabel!
    @IBOutlet weak var touchCnt: UILabel!
    
    @IBOutlet weak var playerView1: UIView!
    @IBOutlet weak var playerView2: UIView!
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
        
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        // 고유서비스명을 가진 브라우저 VC생성
        self.browser = MCBrowserViewController(serviceType: serviceType, session: self.session)
        self.browser.delegate = self
        self.assistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: self.session)
        // 채팅 시작을
        self.assistant.start()
        updateCardImage(0)
        playerView1.layer.borderWidth=2
        playerView2.layer.borderWidth=2
        chipImageView1.image = UIImage(named: "chips.png")
        chipImageView2.image = UIImage(named: "chips.png")
        betImageView1.image = UIImage(named: "chip1.png")
        betImageView2.image = UIImage(named: "chip1.png")
        chipsLabel1.text = "30"
        chipsLabel2.text = "30"
        betLabel1.text = "0"
        betLabel2.text = "0"
    }
    
    func browserViewControllerDidFinish(
        _ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is dismissed (ie the Done button was tapped)
        gameStartButton.isEnabled = true
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func gameStart(_ sender: Any) {
        startView.isHidden = true
        sendNum(0)
        chooseFirstButton.isHidden = false
        chooseFirstButton.isEnabled = true
    }
    
    @IBAction func chooseFirst(_ sender: Any) {
        pickFirstCards()
        chooseFirstButton.isHidden = true
        chooseFirstButton.isEnabled = false
    }
    
    // 블루투스 상대에게 NSData가 보내져왔을때
    // 0: Game Start
    // 1~20: Card Pick for new game set
    // 21~40: Card Pick for choosing First
    // 100: Bet Over    101: One Chip Bet
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID)  {
        DispatchQueue.main.async() {
            let data = NSData(data: data)
            var num : NSInteger = 0
            data.getBytes(&num, length: data.length)
            
            if (num == 0) {            // 상대방이 게임 시작
                self.startView.isHidden = true
            }

            else if (num <= 10) {       // 상대 카드 숫자 (1~10)
                self.game.yourCard = num
                if let index = self.game.cardSet.index(of : self.game.myCard){
                    self.game.cardSet.remove(at: index)
                }
            }
            else if (num <= 20) {       // 내 카드 숫자+10 (11~20)
                self.game.myCard = num - 10
                if let index = self.game.cardSet.index(of : self.game.myCard){
                    self.game.cardSet.remove(at: index)
                }
            }
            
            else if (num <= 30) {       // 상대방이 선플레이어일때 카드숫자+20 (21~30)
                self.updateCardImage(num-20)
                self.game.meFirst = false
                self.updateTurn(myturn: false)
            }
            else if (num <= 40) {       // 내가 선플레이어일때 카드숫자+30 (31~40)
                self.updateCardImage(num-30)
                self.game.meFirst = true
                self.updateTurn(myturn: true)
            }
                
            else if (num == 100) {            // 상대방 배팅이 끝났을 때
                self.gameResult.text = self.game.yourTurn()?.description
                self.updateTurn(myturn: true)
                self.whoseTurn.text = "My turn"
                self.chipsLabel1.text = self.game.myChips.description
                self.chipsLabel2.text = self.game.yourChips.description
                self.betLabel1.text = self.game.myBet.description
                self.betLabel2.text = self.game.yourBet.description
                // 게임을 이긴사람이 카드를 각각 뽑아 전송하기
                if (self.game.nextSet == true){
                    self.pickCards()
                }
            }
                
            // 상대가 배팅을 하나씩 했을 때
            else if (num == 101) {
                //첫 배팅일 경우 숫자를 맞추는 배팅
                if (self.game.myBet > self.game.yourBet){
                    self.game.yourBet += self.game.myBet - self.game.yourBet
                    self.game.yourChips -= self.game.myBet - self.game.yourBet
                }else{                      //일반적인 경우
                    self.game.yourBet += 1
                    self.game.yourChips -= 1
                }
                self.betLabel2.text = self.game.yourBet.description
                self.chipsLabel2.text = self.game.yourChips.description
            }

        }
    }
    
    // send number to other player
    func sendNum(_ num: Int) {
        var temp = num
        let data = NSData(bytes: &temp, length: MemoryLayout<NSInteger>.size)
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
    }
    
    func pickFirstCards() {
        var nums = [1,2,3,4,5,6,7,8,9,10]
        let myFirstCard = nums.remove(at: Int(arc4random_uniform(UInt32(10))))
        let yourFirstCard = nums.remove(at: Int(arc4random_uniform(UInt32(9))))
        
        if (myFirstCard > yourFirstCard) {  // 내가 먼저면 상대카드+20 전송
            sendNum(yourFirstCard+20)
            whoseTurn.text = "myturn"
            self.game.meFirst = true
            self.updateTurn(myturn: true)
        } else {                            // 상대방이 먼저면 상대카드+30 전송
            sendNum(yourFirstCard+30)
            whoseTurn.text = "your turn"
            self.game.meFirst = false
            self.updateTurn(myturn: false)
        }
        updateCardImage(myFirstCard)
        pickCards()
    }
    
    // 카드를 각각 뽑아 전송하기 함수
    func pickCards() {
        let myNewCard = self.game.pickCard()
        let yourNewCard = self.game.pickCard()
        // 자신의 카드, 상대에게는 상대의 카드
        sendNum(myNewCard)
        // 상대의 카드, 상대에게는 자신의 카드
        sendNum(yourNewCard+10)
        self.game.nextSet = false
        self.game.myCard = myNewCard
        self.game.yourCard = yourNewCard
    }
    
    @IBAction func showCard(_ sender: Any) {
        updateCardImage(self.game.myCard)
    }
    
    // touch로 배팅하는 것
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (game.myturn == true && (self.game.myBet - self.game.yourBet < self.game.yourChips)){
            // 첫 배팅은 무조건 myBet과 yourBet이 같도록 하는것
            if (self.game.myBet < self.game.yourBet){
                cntTouch += self.game.yourBet - self.game.myBet
                self.game.myBet += self.game.yourBet - self.game.myBet
                self.game.myChips -= self.game.yourBet - self.game.myBet
            }else{                      //일반적인 경우
                cntTouch += 1
                self.game.myBet += 1
                self.game.myChips -= 1
            }
            
            betLabel1.text = self.game.myBet.description
            chipsLabel1.text = self.game.myChips.description
            touchCnt.text = cntTouch.description
            // 화면 터치는 101을 보냄
            var tempCntTouch = 101
            let data = NSData(bytes: &tempCntTouch, length: MemoryLayout<NSInteger>.size)
            do {
                try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            } catch {
                print(error)
            }
        }
    }
    
    // update card image
    func updateCardImage(_ num: Int) {
        let currentCard = UIImage(named: "card\(num).png")
        self.cardView.image = currentCard
    }
    
    // 초록색 부분의 bet과 chips 수를 update
    func updateBetAndChips() {
        betLabel1.text = self.game.myBet.description
        betLabel2.text = self.game.yourBet.description
        chipsLabel1.text = self.game.myChips.description
        chipsLabel2.text = self.game.yourChips.description
    }
    
    func updateTurn(myturn: Bool) {
        if myturn {
            game.myturn = true
            playerView1.layer.borderColor=UIColor.black.cgColor
            playerView2.layer.borderColor=UIColor.clear.cgColor
        } else {
            game.myturn = false
            playerView2.layer.borderColor=UIColor.black.cgColor
            playerView1.layer.borderColor=UIColor.clear.cgColor
        }
    }
    
    // 기본으로 하나씩 배팅하는 것
    func initialBet() {
        game.myBet += 1
        game.yourBet += 1
        game.myChips -= 1
        game.yourChips -= 1
    }
    
    // 자신의 배팅이 종료되었음을 의미
    @IBAction func shakeButton(_ sender: Any) {
        // 게임 승패가 결정났을 경우 gameResult에 true나 false
        self.gameResult.text = self.game.myTurn()?.description
        updateBetAndChips()
        var betOver = 100
        let data = NSData(bytes: &betOver, length: MemoryLayout<NSInteger>.size)
        
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        updateTurn(myturn: false)
        whoseTurn.text = "your turn"
        cntTouch = 0
        touchCnt.text = cntTouch.description
        
        // 게임을 이긴사람이 카드를 각각 뽑아 전송하기
        if (game.nextSet == true){
            self.pickCards()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func browserBtnTab(_ sender: Any) {
        self.present(self.browser, animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(
        _ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is cancelled
        gameStartButton.isEnabled = false
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
        startView.isHidden = false
    }

}

