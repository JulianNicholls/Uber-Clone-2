//
//  DriverViewController.swift
//  Schnell
//
//  Created by Julian Nicholls on 26/01/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse

class DriverViewController: UITableViewController, CLLocationManagerDelegate {

    var usernames    = [String]()
    var locations   = [CLLocationCoordinate2D]()

    override func viewDidLoad() {
        super.viewDidLoad()

        loadRequests()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return usernames.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("requestCell", forIndexPath: indexPath)

        cell.textLabel!.text = usernames[indexPath.row]

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

    func loadRequests() {
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (driverlocation, error) -> Void in

            if error == nil {
                self.usernames.removeAll(keepCapacity: true)
                self.locations.removeAll(keepCapacity: true)

                let reqQuery = PFQuery(className: "RideRequest")

                reqQuery.whereKey("location", nearGeoPoint: driverlocation!)

                reqQuery.findObjectsInBackgroundWithBlock {
                    (objects, error) -> Void in

                    if error == nil {
                        if let objects = objects as [PFObject]! {
                            for request in objects {
                                if let username = request["username"] as? String {
                                    self.usernames.append(username)
                                }

                                if let loc = request["location"] as? PFGeoPoint {
                                    let cloc = CLLocationCoordinate2DMake(loc.latitude, loc.longitude)

                                    self.locations.append(cloc)
                                }
                            }
                        }

                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    




    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
