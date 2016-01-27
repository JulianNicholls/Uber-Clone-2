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

    var usernames   = [String]()
    var locations   = [CLLocationCoordinate2D]()
    var distances   = [CLLocationDistance]()

    var driverLocation = CLLocationCoordinate2D()

    override func viewDidLoad() {
        super.viewDidLoad()

        loadRequests()

        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("loadRequests"), userInfo: nil, repeats: true)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return locations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("requestCell", forIndexPath: indexPath)

//        let loc     = locations[indexPath.row]
//        let place   = String(format: "%.2f %.2f", arguments: [Double(loc.latitude), Double(loc.longitude)])
        let distance = renderDistance(distances[indexPath.row])

        cell.textLabel!.text = "\(usernames[indexPath.row]) \(distance)"    //  (\(place))

        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "logoutDriver" {
            PFUser.logOut()
            navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: false)
        }
        else {
            if segue.identifier == "showRequest" {
                // Set up data

                if let destCtrl = segue.destinationViewController as? RequestViewController {
                    destCtrl.reqLocation = locations[tableView.indexPathForSelectedRow!.row]
                    destCtrl.reqRider = usernames[tableView.indexPathForSelectedRow!.row]
                }
            }
            else {
                print("Asked for odd segue")
            }
        }
    }

    func renderDistance(dist: CLLocationDistance) -> String {
        let d = Double(dist)

        if d < 600.0 {
            return String(format: "%.0f m", arguments: [d])
        }
        else if d < 20000.0 {
            return String(format: "%.1f km", arguments: [d / 1000.0])
        }

        return String(format: "%.0f km", arguments: [d / 1000.0])
    }
    
    func loadRequests() {
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (dloc, error) -> Void in

            if error == nil {
                self.driverLocation = CLLocationCoordinate2DMake((dloc?.latitude)!, (dloc?.longitude)!)

                self.usernames.removeAll(keepCapacity: true)
                self.locations.removeAll(keepCapacity: true)
                self.distances.removeAll(keepCapacity: true)

                let reqQuery = PFQuery(className: "RideRequest")

                reqQuery.whereKey("location", nearGeoPoint: dloc!)
                reqQuery.limit = 10

                reqQuery.findObjectsInBackgroundWithBlock {
                    (objects, error) -> Void in

                    if error == nil {
                        if let objects = objects as [PFObject]! {
                            for request in objects {
                                if request["driverResponded"] == nil {
                                    if let username = request["username"] as? String {
                                        self.usernames.append(username)
                                    }

                                    if let loc = request["location"] as? PFGeoPoint {
                                        let cloc = CLLocationCoordinate2DMake(loc.latitude, loc.longitude)

                                        self.locations.append(cloc)

                                        let reqLoc = CLLocation(latitude: cloc.latitude, longitude: cloc.longitude)
                                        let drvLoc = CLLocation(latitude: (dloc?.latitude)!, longitude: (dloc?.longitude)!)

                                        self.distances.append(drvLoc.distanceFromLocation(reqLoc))
                                    }
                                }
                            }
                        }

                        self.tableView.reloadData()
                    }
                    else {
                        print(error?.localizedDescription)
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
