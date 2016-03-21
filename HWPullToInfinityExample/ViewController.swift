//
//  ViewController.swift
//  HWPullToInfinityExample
//
//  Created by Hugues Blocher on 22/01/16.
//  Copyright © 2016 hw. All rights reserved.
//

import UIKit

let handlerDelay = 1.5

class ViewController: UITableViewController {

    var rows: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup
        rows = self.randomize()
        tableView.reloadData()
        
        // Pull to refresh
        tableView.addPullToRefreshWithActionHandler { () -> Void in
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(handlerDelay * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.tableView.stopPullToRefresh()
                self.rows = self.randomize()
                self.tableView.reloadData()
            }
        }
        tableView.pullRefreshColor = UIColor.darkGrayColor()
        
        // Infinite scroll
        tableView.addInfiniteScrollingWithActionHandler { () -> Void in
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(handlerDelay * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.tableView.infiniteScrollingView.stopAnimating()
                let temp = self.randomize()
                for row in temp {
                    self.rows.append(row)
                    self.tableView.beginUpdates()
                    self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.rows.count - 1, inSection: 0)], withRowAnimation: .Fade)
                    self.tableView.endUpdates()
                }
            }
        }
        tableView.infiniteScrollingView.color = UIColor.darkGrayColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return rows.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell=UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "mycell")
        cell.textLabel!.text = rows[indexPath.row]
        return cell
    }
    
    func randomize() -> [String] {
        var array: [String] = []
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".characters
        let lettersLength = UInt32(letters.count)
        for _ in 1...40 {
            let randomCharacters = (0..<8).map { i -> String in
                let offset = Int(arc4random_uniform(lettersLength))
                let c = letters[letters.startIndex.advancedBy(offset)]
                return String(c)
            }
            array.append(randomCharacters.joinWithSeparator(""))
        }
        return array
    }
}

