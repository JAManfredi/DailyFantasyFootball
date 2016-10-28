//
//  ImportData.swift
//  DFF
//
//  Created by Jared Manfredi on 9/14/15.
//  Copyright © 2015 jm. All rights reserved.
//

import Foundation
import RealmSwift

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class ImportData {
    fileprivate var week = 1
    fileprivate var teamDic = Dictionary<String,Array<String>>()
    fileprivate var defenseDic = Dictionary<String,Array<Int>>()
    
    convenience init(forWeek: Int) {
        self.init()
        self.week = forWeek
    }
    
    // MARK: Setup Data
    
    fileprivate func setupData(_ finished: ()->()) {
        self.populateSchedule { () -> () in
            self.populateTeamDefenseData({ () -> () in
                finished()
            })
        }
    }
    
    // MARK: Populate Schedule Dictionary
    
    fileprivate func populateSchedule(_ finished: ()->())
    {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        let docDirectory = paths[0]
        let schedPath = docDirectory + "/NFL/2015-nfl-schedule.csv"
        
        do {
            let schedString = try NSString(contentsOfFile: schedPath, encoding: String.Encoding.utf8.rawValue)
            let teamSchedArray = schedString.components(separatedBy: "\n")
            for x in 1 ..< 33 {
                // Save Each Row
                let teamSchedString = teamSchedArray[x]
                let parsedWeek = teamSchedString.components(separatedBy: ",")
                
                var team = String()
                for game in parsedWeek {
                    if team.isEmpty {
                        team = game
                        teamDic[team] = Array<String>()
                        continue
                    }
                    teamDic[team]!.append(game)
                }
            }
            finished()
        } catch {
            print("Error Saving Schedule")
        }
    }
    
    // MARK: Populate Team Defense
    
    fileprivate func populateTeamDefenseData(_ finished: ()->())
    {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        let docDirectory = paths[0]
        let teamDefDataPath = docDirectory + "/NFL/team_defense.txt"
        
        do {
            let defString = try NSString(contentsOfFile: teamDefDataPath, encoding: String.Encoding.utf8.rawValue)
            let defArray = defString.components(separatedBy: "\n")
            for x in 0 ..< defArray.count {
                let defRow = defArray[x]
                if (defRow.characters.count > 0) {
                    let parsedRowData = defRow.components(separatedBy: "|")
                    if (parsedRowData.count > 0) {
                        let teamAbbr = mapTeamNameToAbb(parsedRowData[0])
                        defenseDic[teamAbbr] = [ Int(parsedRowData[2])!, Int(parsedRowData[3])!, Int(parsedRowData[4])! ]
                    }
                }
            }
            finished()
        } catch {
            print("Error Saving Team Defense Data")
        }
    }
    
    // MARK: Get Opponent For Team And Week Helper Func
    
    fileprivate func getOpponent(_ team: String, week: Int) -> (opponent: String, homeGame: Bool)
    {
        var opponentArray = teamDic[team]
        let rawOpponent = opponentArray![week-1]
        
        if (rawOpponent == "BYE") {
            return (rawOpponent, false)
        }

        let awayGame = rawOpponent.hasPrefix("@")
        if (awayGame) {
            let opponent = rawOpponent.substring(from: rawOpponent.characters.index(rawOpponent.startIndex, offsetBy: 1))
            return (opponent, false)
        } else {
            return (rawOpponent, true)
        }
    }
    
    // MARK: Import All
    
    func importNFLData(_ finished: ()->())
    {
        self.setupData { () -> () in
            self.importDraftKingsData({ () -> () in
//                self.importQBData({ () -> () in
//                    print("--> QB Data Imported")
//                    self.importRBData({ () -> () in
//                        print("--> RB Data Imported")
                        self.importWRData({ () -> () in
                            print("--> WR Data Imported")
//                            self.importTEData({ () -> () in
//                                print("--> TE Data Imported")
//                                print("Setup Complete!")
                            
                                self.calculatePlayerScores()
//                            })
                        })
//                    })
//                })
            })
        }
    }
    
    fileprivate func calculatePlayerScores()
    {
        do {
            let realm = try Realm()
            let wrs = realm.objects(Player.self).filter("position = 'WR' AND games_played > 0 AND salary > 0 AND receptions >= 1")
            var totalPlayerScores = 0.0
            
            // Set Initial Score & Get Avg
            for wr: Player in wrs {
                // salary / (targets / gamesplayed) / 100
                // Rec Yards Per Game / 10
                // Receiving TDs * 2
                // Home Game: NO = 0 or 2pts
                // Defense Pass Standing / 4
                
//                if (wr.name_code == "DonteMoncrief" || wr.name_code == "MarquessWilson") {
//                    print("Stop")
//                }
                
                // WR Score
//                let nameCode = wr.name_code
//                let name = wr.full_name
                let metricOne = Double(wr.targets / wr.games_played) / 1.4
                let metricTwo = wr.rec_yards_per_game / 10
                let metricThree = Double(wr.receiving_tds) * 4
                let metricFour = (wr.home_game) ? 1.0 : 0
                let metricFive = Double(wr.opponent_pass_d) / 4.0
                let total = metricOne + metricTwo + metricThree + metricFour + metricFive
                
//                if (wr.name_code == "DonteMoncrief" || wr.name_code == "MarquessWilson") {
//                    print("Stop")
//                }
                
                // Save For Player
                try realm.write {
                    wr.player_score = total
                }
                
                if (wr.games_played >= 1 && wr.receptions >= 1) {
                    totalPlayerScores += total
                }
            }
            
            // Loop Again & Adjust Score
            let avg_player_score = totalPlayerScores/Double(wrs.count)
            for wr: Player in wrs {
                var psAdj = 0.0
                if (avg_player_score > 0) {
                    psAdj = wr.player_score - avg_player_score
                } else {
                    psAdj = wr.player_score + avg_player_score
                }

                // Save Adjusted Player Score
                try realm.write {
                    wr.player_score = psAdj
                }
            }
            
            let wrss = realm.objects(Player.self).filter("position = 'WR' AND games_played > 0 AND salary > 0 AND receptions >= 1").sorted(byProperty: "player_score", ascending: false)
            for wrr: Player in wrss {
                print("\(wrr.full_name)\t\t\t\(wrr.player_score) \(wrr.salary) \(wrr.targets) \(wrr.receiving_yards) \(wrr.receiving_tds) \(wrr.opponent_pass_d)")
            }
            
        } catch {
            print("Error Setting Up Player Scores")
        }
    }
    
    // MARK: Import Draft Kings Weekly Data
    
    fileprivate func importDraftKingsData(_ finished: @escaping ()->())
    {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        let docDirectory = paths[0]
        let dkSalariesPath = docDirectory + "/NFL/DKSalaries.csv"
        
        do {
            let dkString = try NSString(contentsOfFile: dkSalariesPath, encoding: String.Encoding.utf8.rawValue)
            let dkArray = dkString.components(separatedBy: "\n")
            
            // Create Objects In Background
            DispatchQueue.global(qos: .background).async {
                autoreleasepool {
                    do {
                        defer {
                            DispatchQueue.main.async {
                                finished()
                            }
                        }
                        
                        let realm = try Realm()
                        for x in 1 ..< dkArray.count {
                            let dkRow = dkArray[x]
                            if (dkRow.characters.count > 0) {
                                
                                let parsedRowData = dkRow.components(separatedBy: ",")
                                let formattedDataArray = parsedRowData.map({
                                    data in
                                    data.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
                                })
                                
                                let tempName = formattedDataArray[1]
                                let nameCode = tempName.replacingOccurrences(of: " ", with:"")
                                
                                realm.beginWrite()
                                
                                // Player Info From Draft Kings
                                let player: Player =  realm.create(Player.self, value: [ "name_code" : nameCode ], update: true)
                                
                                player.position = formattedDataArray[0]
                                player.full_name = formattedDataArray[1]
                                //player.name_code = nameCode
                                player.salary = Int(formattedDataArray[2])!
                                player.points_per_game = Double(formattedDataArray[4])!
                                
                                let formattedTeam = formattedDataArray[5].uppercased()
                                player.team = formattedTeam
                                
                                // Opponent Info From Schedule
                                let game = self.getOpponent(formattedTeam, week: self.week)
                                if (!game.opponent.isEmpty) {
                                    player.weeks_opponent = game.opponent
                                    player.home_game = game.homeGame
                                }
                                
                                // Defense Stats From Yahoo
                                var opponentDefenseRanks: Array<Int>? = self.defenseDic[game.opponent]
                                if (opponentDefenseRanks != nil && opponentDefenseRanks?.count >= 3) {
                                    player.opponent_rush_d = opponentDefenseRanks![0]
                                    player.opponent_pass_d = opponentDefenseRanks![1]
                                    player.opponent_total_d = opponentDefenseRanks![2]
                                }

                                // Commit
                                try realm.commitWrite()
                            }
                        }
                    } catch {
                        print("Error Iterating & Saving Player DK Data")
                    }
                } // autoreleasepool
            } // dispatch_async
        } catch {
            print("Error Saving DraftKings Data")
        }
    }
    
    fileprivate func importQBData(_ finished: @escaping ()->())
    {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        let docDirectory = paths[0]
        let qbDataPath = docDirectory + "/NFL/qb_data.txt"
        
        do {
            let qbString = try NSString(contentsOfFile: qbDataPath, encoding: String.Encoding.utf8.rawValue)
            let qbArray = qbString.components(separatedBy: "\n")
            
            // Update Objects In Background
            DispatchQueue.global(qos: .background).async {
                autoreleasepool {
                    do {
                        defer {
                            DispatchQueue.main.async {
                                finished()
                            }
                        }
                        
                        let realm = try Realm()
                        for x in 0 ..< qbArray.count {
                            let qbRow = qbArray[x]
                            if (qbRow.characters.count > 0) {
                                realm.beginWrite()
                                
                                let parsedRowData = qbRow.components(separatedBy: "|")
                                let formattedDataArray = parsedRowData.map({
                                    data in
                                    data.replacingOccurrences(of: "N/A", with: "0")
                                })
                                let nameCode = formattedDataArray[0]
                                
                                // Name Team G QBRat Comp Att5 Pct Yds Y/G Y/A9 TD Int11 Rush Yds Y/G Avg TD Sack YdsL18 Fum FumL
                                let player: Player =  realm.create(Player.self, value: [ "name_code" : nameCode ], update: true)
                                
                                player.games_played = Int(formattedDataArray[2])!
                                player.qb_rating = Double(formattedDataArray[3])!
                                player.completions = Int(formattedDataArray[4])!
                                player.pass_attempts = Int(formattedDataArray[5])!
                                player.comp_percentage = Double(formattedDataArray[6])!
                                player.pass_yards_total = Int(formattedDataArray[7])!
                                player.pass_yards_per_game = Double(formattedDataArray[8])!
                                player.pass_yards_per_attempt = Double(formattedDataArray[9])!
                                player.pass_tds = Int(formattedDataArray[10])!
                                player.ints = Int(formattedDataArray[11])!
                                player.sacks = Int(formattedDataArray[17])!
                                player.sack_yards_lost = Double(formattedDataArray[18])!
                                player.rush_attempts = Int(formattedDataArray[12])!
                                player.rush_yards = Int(formattedDataArray[13])!
                                player.rush_yards_per_game = Double(formattedDataArray[14])!
                                player.rush_yards_avg = Double(formattedDataArray[15])!
                                player.rush_tds = Int(formattedDataArray[16])!
                                player.fumbles = Int(formattedDataArray[19])!
                                player.fumbles_lost = Double(formattedDataArray[20])!
                                
                                // Commit
                                try realm.commitWrite()
                            }
                        }
                    } catch {
                        print("Error Iterating & Saving Player QB Data")
                    }
                } // autoreleasepool
            } // dispatch_async
        } catch {
            print("Error Saving QB Data")
        }
    }

    fileprivate func importRBData(_ finished:@escaping ()->())
    {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        let docDirectory = paths[0]
        let rbDataPath = docDirectory + "/NFL/rb_data.txt"
        
        do {
            let rbString = try NSString(contentsOfFile: rbDataPath, encoding: String.Encoding.utf8.rawValue)
            let rbArray = rbString.components(separatedBy: "\n")
            // Update Objects In Background
            DispatchQueue.global(qos: .background).async {
                autoreleasepool {
                    do {
                        defer {
                            DispatchQueue.main.async {
                                finished()
                            }
                        }
                        
                        let realm = try Realm()
                        for x in 0 ..< rbArray.count {
                            let rbRow = rbArray[x]
                            if (rbRow.characters.count > 0) {
                                realm.beginWrite()
                                
                                let parsedRowData = rbRow.components(separatedBy: "|")
                                let formattedDataArray = parsedRowData.map({
                                    data in
                                    data.replacingOccurrences(of: "N/A", with: "0")
                                })
                                let nameCode = formattedDataArray[0]
                                
                                //Name Team G Rush Yds Y/G Avg TD7 Rec Tgt Yds Y/G Avg Lng YAC 1stD TD Fum FumL18
                                let player: Player =  realm.create(Player.self, value: [ "name_code" : nameCode ], update: true)
                                
                                player.games_played = Int(formattedDataArray[2])!
                                player.rush_attempts = Int(formattedDataArray[3])!
                                player.rush_yards = Int(formattedDataArray[4])!
                                player.rush_yards_per_game = Double(formattedDataArray[5])!
                                player.rush_yards_avg = Double(formattedDataArray[6])!
                                player.rush_tds = Int(formattedDataArray[7])!
                                player.fumbles = Int(formattedDataArray[17])!
                                player.fumbles_lost = Double(formattedDataArray[18])!
                                player.receptions = Int(formattedDataArray[17])!
                                player.targets = Int(formattedDataArray[17])!
                                player.receiving_yards = Double(formattedDataArray[18])!
                                player.rec_yards_per_game = Double(formattedDataArray[18])!
                                player.rec_yards_avg = Double(formattedDataArray[18])!
                                player.rec_long = Double(formattedDataArray[18])!
                                player.yards_after_catch = Double(formattedDataArray[18])!
                                player.first_downs = Int(formattedDataArray[17])!
                                player.receiving_tds = Int(formattedDataArray[17])!
                                
                                // Commit
                                try realm.commitWrite()
                            }
                        }
                    } catch {
                        print("Error Iterating & Saving Player RB Data")
                    }
                } // autoreleasepool
            } // dispatch_async
        } catch {
            print("Error Saving RB Data")
        }
    }

    fileprivate func importWRData(_ finished: @escaping ()->())
    {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        let docDirectory = paths[0]
        let wrDataPath = docDirectory + "/NFL/wr_data.txt"
        
        do {
            let wrString = try NSString(contentsOfFile: wrDataPath, encoding: String.Encoding.utf8.rawValue)
            let wrArray = wrString.components(separatedBy: "\n")
            // Update Objects In Background
            DispatchQueue.global(qos: .background).async {
                autoreleasepool {
                    do {
                        defer {
                            DispatchQueue.main.async {
                                finished()
                            }
                        }
                        
                        let realm = try Realm()
                        for x in 0 ..< wrArray.count {
                            let wrRow = wrArray[x]
                            if (wrRow.characters.count > 0) {
                                let parsedRowData = wrRow.components(separatedBy: "|")
                                let formattedDataArray = parsedRowData.map({
                                    data in
                                    data.replacingOccurrences(of: "N/A", with: "0")
                                })
                                let nameCode = formattedDataArray[0]
                                
                                // Blank Row Check
                                guard !nameCode.isEmpty && nameCode.characters.count > 0 else {
                                    continue
                                }
                                
                                realm.beginWrite()
                                
                                //Name|Team|G|3|Rec|Tgt|Yds|Y/G|Avg|Lng|YAC|1stD|TD|13|KR|Yds|Avg|Long|TD|19|PR|Yds|Avg|Long|TD|25|Fum|FumL|
                                let player: Player =  realm.create(Player.self, value: [ "name_code" : nameCode ], update: true)
                                
                                player.games_played = Int(formattedDataArray[2])!
                                player.receptions = Int(formattedDataArray[4])!
                                player.targets = Int(formattedDataArray[5])! //*****
                                player.receiving_yards = Double(formattedDataArray[6])!
                                player.rec_yards_per_game = Double(formattedDataArray[7])! //*****
                                player.rec_yards_avg = Double(formattedDataArray[8])!
                                player.rec_long = Double(formattedDataArray[9])!
                                player.yards_after_catch = Double(formattedDataArray[10])!
                                player.first_downs = Int(formattedDataArray[11])!
                                player.receiving_tds = Int(formattedDataArray[12])! //*****
                                player.kick_returns = Int(formattedDataArray[14])!
                                player.kick_return_yards = Double(formattedDataArray[15])!
                                player.kick_return_avg = Double(formattedDataArray[16])!
                                player.kick_return_long = Int(formattedDataArray[17])!
                                player.kick_return_tds = Int(formattedDataArray[18])!
                                player.punt_returns = Int(formattedDataArray[20])!
                                player.punt_return_yards = Double(formattedDataArray[21])!
                                player.punt_return_avg = Double(formattedDataArray[22])!
                                player.punt_return_long = Int(formattedDataArray[23])!
                                player.punt_return_tds = Int(formattedDataArray[24])!
                                player.fumbles = Int(formattedDataArray[26])!
                                player.fumbles_lost = Double(formattedDataArray[27])!
                                
                                // Commit
                                try realm.commitWrite()
                            }
                        }
                    } catch {
                        print("Error Iterating & Saving Player WR Data")
                    }
                } // autoreleasepool
            } // dispatch_async
        } catch {
            print("Error Saving WR Data")
        }
    }

    fileprivate func importTEData(_ finished: @escaping ()->())
    {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        let docDirectory = paths[0]
        let teDataPath = docDirectory + "/NFL/te_data.txt"
        
        do {
            let teString = try NSString(contentsOfFile: teDataPath, encoding: String.Encoding.utf8.rawValue)
            let teArray = teString.components(separatedBy: "\n")
            // Update Objects In Background
            DispatchQueue.global(qos: .background).async {
                autoreleasepool {
                    do {
                        defer {
                            DispatchQueue.main.async {
                                finished()
                            }
                        }
                        
                        let realm = try Realm()
                        for x in 0 ..< teArray.count {
                            let teRow = teArray[x]
                            if (teRow.characters.count > 0) {
                                realm.beginWrite()
                                
                                let parsedRowData = teRow.components(separatedBy: "|")
                                let formattedDataArray = parsedRowData.map({
                                    data in
                                    data.replacingOccurrences(of: "N/A", with: "0")
                                })
                                let nameCode = formattedDataArray[0]
                                
                                //Name|Team|G|3|Rec|Tgt|Yds|Y/G|Avg|Lng|YAC|1stD|TD|13|Rush|Yds|Y/G|Avg|TD|19|Fum|FumL|
                                let player: Player =  realm.create(Player.self, value: [ "name_code" : nameCode ], update: true)
                                
                                player.games_played = Int(formattedDataArray[2])!
                                player.receptions = Int(formattedDataArray[4])!
                                player.targets = Int(formattedDataArray[5])!
                                player.receiving_yards = Double(formattedDataArray[6])!
                                player.rec_yards_per_game = Double(formattedDataArray[7])!
                                player.rec_yards_avg = Double(formattedDataArray[8])!
                                player.rec_long = Double(formattedDataArray[9])!
                                player.yards_after_catch = Double(formattedDataArray[10])!
                                player.first_downs = Int(formattedDataArray[11])!
                                player.receiving_tds = Int(formattedDataArray[12])!
                                player.rush_attempts = Int(formattedDataArray[14])!
                                player.rush_yards = Int(formattedDataArray[15])!
                                player.rush_yards_per_game = Double(formattedDataArray[16])!
                                player.rush_yards_avg = Double(formattedDataArray[17])!
                                player.rush_tds = Int(formattedDataArray[18])!
                                player.fumbles = Int(formattedDataArray[20])!
                                player.fumbles_lost = Double(formattedDataArray[21])!
                                
                                // Commit
                                try realm.commitWrite()
                            }
                        }
                    } catch {
                        print("Error Iterating & Saving Player TE Data")
                    }
                } // autoreleasepool
            } // dispatch_async
        } catch {
            print("Error Saving TE Data")
        }
    }
    
    // MARK: Map Team Name To Abbreviation
    
    fileprivate func mapTeamNameToAbb(_ name: String) -> String
    {
        switch (name) {
        case "DenverBroncos":
            return "DEN"
        case "BaltimoreRavens":
            return "BAL"
        case "CincinnatiBengals":
            return "CIN"
        case "WashingtonRedskins":
            return "WAS"
        case "JacksonvilleJaguars":
            return "JAX"
        case "CarolinaPanthers":
            return "CAR"
        case "TennesseeTitans":
            return "TEN"
        case "DallasCowboys":
            return "DAL"
        case "SanDiegoChargers":
            return "SD"
        case "BuffaloBills":
            return "BUF"
        case "TampaBayBuccaneers":
            return "TB"
        case "NewYorkJets":
            return "NYJ"
        case "ChicagoBears":
            return "CHI"
        case "HoustonTexans":
            return "HOU"
        case "ClevelandBrowns":
            return "CLE"
        case "IndianapolisColts":
            return "IND"
        case "St.LouisRams":
            return "STL"
        case "MiamiDolphins":
            return "MIA"
        case "SeattleSeahawks":
            return "SEA"
        case "PittsburghSteelers":
            return "PIT"
        case "KansasCityChiefs":
            return "KC"
        case "OaklandRaiders":
            return "OAK"
        case "GreenBayPackers":
            return "GB"
        case "ArizonaCardinals":
            return "ARI"
        case "NewOrleansSaints":
            return "NO"
        case "NewYorkGiants":
            return "NYG"
        case "NewEnglandPatriots":
            return "NE"
        case "DetroitLions":
            return "DET"
        case "SanFrancisco49ers":
            return "SF"
        case "MinnesotaVikings":
            return "MIN"
        case "PhiladelphiaEagles":
            return "PHI"
        case "AtlantaFalcons":
            return "ATL"
        default:
            return "N/A"
        }
    }
}
