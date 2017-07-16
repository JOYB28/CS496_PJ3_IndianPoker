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

class game {}

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate, UITextFieldDelegate {
    
    let serviceType = "Indian-Poker"
    
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    var session: MCSession!
    var peerID: MCPeerID!
    
    var numset = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]

    @IBOutlet weak var cardView: UIImageView!
    @IBOutlet weak var leftCards: UILabel!
    @IBOutlet weak var player1betchips: UIImageView!
    @IBOutlet weak var player2betchips: UIImageView!
    @IBOutlet weak var player1leftchips: UIImageView!
    @IBOutlet weak var player2leftchips: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        player1betchips.image = UIImage(named: "chip1.png")
        player2betchips.image = UIImage(named: "chip1.png")
        player1leftchips.image = UIImage(named: "chips.png")
        player2leftchips.image = UIImage(named: "chips.png")
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cardChangeButton(_ sender: Any) {
        if (numset.count == 0) {            //new card deck
            numset = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
        }
        
        var index = Int(arc4random_uniform(UInt32(numset.count)))
        
        let data = NSData(bytes: &index, length: MemoryLayout<NSInteger>.size)
        
        do {
            try self.session.send(data as Data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print(error)
        }
        
        let cardNum = numset.remove(at: index)
        let currentCard = UIImage(named: "card\(cardNum).png")
        self.cardView.image = currentCard
        leftCards.text = numset.description
    }
    
    func updateCard(index: Int, fromPeer peerID: MCPeerID) {
        if (numset.count == 0) {            //new card deck
            numset = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
        }
        numset.remove(at: index)
        //let currentCard = UIImage(named: "card\(cardNum).png")
        //self.cardView.image = currentCard
        leftCards.text = numset.description
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
            
            // 카드 업데이트
            self.updateCard(index: u2num, fromPeer: peerID)
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

