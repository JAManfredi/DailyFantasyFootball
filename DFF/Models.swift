//
//  Models.swift
//  DFF
//
//  Created by Jared Manfredi on 9/15/15.
//  Copyright © 2015 jm. All rights reserved.
//

import Foundation
import RealmSwift

class Player: Object
{
    dynamic var full_name: String = ""
    dynamic var name_code: String = ""
    dynamic var team: String = ""
    dynamic var salary: Int = 0
    dynamic var position: String = ""
    dynamic var weeks_opponent: String = ""
    dynamic var opponent_total_d: Int = 0
    dynamic var opponent_rush_d: Int = 0
    dynamic var opponent_pass_d: Int = 0
    dynamic var home_game: Bool = false
    dynamic var points_per_game: Double = 0.0
    dynamic var games_played: Int = 0
    dynamic var player_score: Double = 0.0
    
    // QB
    dynamic var qb_rating: Double = 0.0
    dynamic var completions: Int = 0
    dynamic var pass_attempts: Int = 0
    dynamic var comp_percentage: Double = 0.0
    dynamic var pass_yards_total: Int = 0
    dynamic var pass_yards_per_game: Double = 0.0
    dynamic var pass_yards_per_attempt: Double = 0.0
    dynamic var pass_tds: Int = 0
    dynamic var ints: Int = 0
    dynamic var sacks: Int = 0
    dynamic var sack_yards_lost: Double = 0.0
    
    // QB & RB
    dynamic var rush_attempts: Int = 0
    dynamic var rush_yards: Int = 0
    dynamic var rush_yards_per_game: Double = 0.0
    dynamic var rush_yards_avg: Double = 0.0
    dynamic var rush_tds: Int = 0
    dynamic var fumbles: Int = 0
    dynamic var fumbles_lost: Double = 0.0
    
    // RB & WR
    dynamic var receptions: Int = 0
    dynamic var targets: Int = 0
    dynamic var receiving_yards: Double = 0.0
    dynamic var rec_yards_per_game: Double = 0.0
    dynamic var rec_yards_avg: Double = 0.0
    dynamic var rec_long: Double = 0.0
    dynamic var yards_after_catch: Double = 0.0
    dynamic var first_downs: Int = 0
    dynamic var receiving_tds: Int = 0
    
    // WR
    dynamic var kick_returns: Int = 0
    dynamic var kick_return_yards: Double = 0.0
    dynamic var kick_return_avg: Double = 0.0
    dynamic var kick_return_long: Int = 0
    dynamic var kick_return_tds: Int = 0
    dynamic var punt_returns: Int = 0
    dynamic var punt_return_yards: Double = 0.0
    dynamic var punt_return_avg: Double = 0.0
    dynamic var punt_return_long: Int = 0
    dynamic var punt_return_tds: Int = 0
    
    // Primary Key
    override static func primaryKey() -> String?
    {
        return "name_code"
    }
    
    // Index
    override static func indexedProperties() -> [String]
    {
        return ["name_code, position"]
    }
}