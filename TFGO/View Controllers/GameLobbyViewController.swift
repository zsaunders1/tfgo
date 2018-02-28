//
//  GameLobbyViewController.swift
//  TFGO
//
//  Created by Sam Schlang on 2/10/18.
//  Copyright © 2018 University of Chicago. All rights reserved.
//

import UIKit

class LobbyCustomViewCell: UITableViewCell {
    @IBOutlet weak var gamemodeLabel: UILabel!
    @IBOutlet weak var gameNameLabel: UILabel!
    @IBOutlet weak var gameDistanceLabel: UILabel!
    @IBOutlet weak var userCollection: UICollectionView!
}

class GameLobbyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private var hasChosenGame = false
    private var showPublic = true

    override func viewDidLoad() {
        super.viewDidLoad()
        self.table.dataSource = self;
        self.table.delegate = self;
        runTimer()
        updateGames()

        DispatchQueue.global(qos: .background).async {
            if  gameState.getConnection().sendData(data: ShowGamesMsg()).isSuccess {
                while !self.hasChosenGame {
                    if handleMsgFromServer() { }
                }
            }
        }
    }
    
    private var gamesPrivate: [Game] = []
    private var gamesPublic: [Game] = []
    private var gamesList: [Game] {
        get {
            return showPublic ? gamesPublic : gamesPrivate
        }
    }
    
    @IBAction func segmentButtonPress(_ sender: UISegmentedControl) {
        showPublic = !showPublic
        table.reloadData()
    }
    
    private var updateTimer = Timer()
    
    private func runTimer() {
        updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(GameLobbyViewController.updateGames)), userInfo: nil, repeats: true)
    }
    
    @IBOutlet weak var table: UITableView!
    
    @objc private func updateGames() {
        gamesPrivate = []
        gamesPublic = []
        for game in gameState.getFoundGames() {
            game.isPrivate() ? gamesPrivate.append(game) : gamesPublic.append(game)
        }
        table.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gamesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Game", for: indexPath) as! LobbyCustomViewCell
        let game = gamesList[indexPath.row]
        switch game.getMode() {
        case .cp:
            cell.gamemodeLabel.text = "◆"
        case .multi:
            cell.gamemodeLabel.text = "⇥"
        case .payload:
            cell.gamemodeLabel.text = "❖"
        }
        cell.gameNameLabel.text = game.getName()!
        cell.gameDistanceLabel.text = "\(gameState.getDistanceFromGame(game: game)) units away"
        cell.layer.cornerRadius = 8.0
        cell.backgroundColor = randomColor()
        cell.userCollection.delegate = self
        cell.userCollection.dataSource = self
        cell.userCollection.backgroundColor = cell.backgroundColor
        cell.userCollection.reloadData()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let cell = collectionView.superview?.superview?.superview as? LobbyCustomViewCell {
            for game in gamesList {
                if cell.gameNameLabel.text == game.getName() {
                    return game.getPlayers().count
                }
            }
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "icon", for: indexPath) as! IconViewCell
        if let lobbyCell = collectionView.superview?.superview as? LobbyCustomViewCell {
            let game = gamesList[(table.indexPath(for: lobbyCell)?.row)!]
            cell.label.text = game.getPlayers()[indexPath.row].getIcon()
        }
        cell.backgroundColor = randomColor()
        cell.layer.cornerRadius = 8.0
        cell.clipsToBounds = true
        return cell
    }
    
    @IBAction func selectGame(_ sender: UIButton) {
        if let cell = sender.superview?.superview as? LobbyCustomViewCell {
            let game = gamesList[(table.indexPath(for: cell)?.row)!]
            if gameState.getConnection().sendData(data: ShowGameInfoMsg(IDtoShow: game.getID()!)).isSuccess {
                if gameState.setCurrentGame(to: game) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        if handleMsgFromServer() {}
                    }
                    performSegue(withIdentifier: "gameSelect", sender: nil)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        updateTimer.invalidate()
        hasChosenGame = true
    }

}
