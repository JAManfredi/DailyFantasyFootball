//
//  ViewController.swift
//  DFF
//
//  Created by Jared Manfredi on 9/14/15.
//  Copyright © 2015 jm. All rights reserved.
//

import Cocoa
import Foundation
import RealmSwift

class ViewController: NSViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let setup = ImportData(forWeek: 2)
        setup.importNFLData { () -> () in
            // Load View
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

