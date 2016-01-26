//
//  DriverViewController.swift
//  Schnell
//
//  Created by Julian Nicholls on 26/01/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse

class DriverViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("requestCell", forIndexPath: indexPath)

        cell.textLabel!.text = "Test \(indexPath.row + 1)"

        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "logoutDriver" {
            PFUser.logOut()
            navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: false)
        }
        else {
            print("Asked for odd segue")
        }
    }





    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
