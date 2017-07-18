//
//  game.swift
//  YunaFirstApp
//
//  Created by user on 2017. 7. 18..
//  Copyright © 2017년 Yuna Seol. All rights reserved.
//

import Foundation

class Game {
    var cardSet = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
    var myChips = 30
    var yourChips = 30
    var myBet = 0
    var yourBet = 0
    var meFirst = false
    var myturn = false
    var myCard = 0
    var yourCard = 0
    var nextSet = false
    var newSet = false
    
    // pickCard : 현재의 카드셋에서 카드를 하나 뽑아 그 "숫자"를 리턴한다.
    func pickCard() -> Int {
        if (cardSet.count == 0) {            //new card deck
            cardSet = [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10]
        }
        let index = Int(arc4random_uniform(UInt32(cardSet.count)))
        myCard = cardSet.remove(at: index)
        return myCard
    }
    
    // myTurn : 현재의 mybet, yourbet으로 자신의 차례를 진행한다.
    func myTurn() -> Bool? {
        if (myBet == 1 || myBet < yourBet) {          // die, 내가 지는 것
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
            newSet = false
        } else if ( myCard > yourCard) {    // Card open (win)
            myChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            meFirst = true
            nextSet = true
            newSet = true
        } else if ( myCard == yourCard) {   //          (draw)
            // next Stage
            nextSet = true
            newSet = true
        } else if ( myCard < yourCard) {    //          (loose)
            yourChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            meFirst = false
            newSet = true
        }
        
        // Game Over
        if (yourChips == 0 && yourBet == 0 || (yourChips == 0 && myBet == yourBet)) {
            return true
        } else if (myChips == 0 && myBet == 0 || (myChips == 0 && myBet == yourBet)) {
            return false
        }
        return nil
    }
    
    // myTurn : 현재의 mybet, yourbet으로 자신의 차례를 진행한다.
    func yourTurn() -> Bool? {
        if (yourBet == 1  || yourBet < myBet) {          // die
            myChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            if (yourCard == 10) {
                myChips += 10
                yourChips -= 10
            }
            nextSet = true
            meFirst = true
            newSet = true
        } else if ( yourBet > myBet) {  // more bet
            newSet = false
        } else if ( myCard > yourCard) {    // Card open (win)
            myChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            meFirst = true
            nextSet = true
            newSet = true
        } else if ( myCard == yourCard) {   //           (draw)
            // next Stage
            nextSet = false
            newSet = true
        } else if ( myCard < yourCard) {    //           (loose)
            yourChips += (myBet + yourBet)
            myBet = 0
            yourBet = 0
            meFirst = false
            newSet = true
        }
        // Game Over
        if (yourChips == 0 && yourBet == 0 || (yourChips == 0 && myBet == yourBet)) {
            return true
        } else if (myChips == 0 && myBet == 0 || (myChips == 0 && myBet == yourBet)) {
            return false
        }
        return nil
    }
}
