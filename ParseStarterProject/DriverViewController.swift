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

    var locationManager = CLLocationManager()

    var refresher = UIRefreshControl()

    var adding = false

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()

        loadRequests()

        NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: Selector("loadRequests"), userInfo: nil, repeats: true)

        // Add a pull to refresh

        refresher.attributedTitle = NSAttributedString(string: "Pull to see new ride requests")
        refresher.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)

        tableView.addSubview(refresher)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("requestCell", forIndexPath: indexPath)

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
                if let destCtrl = segue.destinationViewController as? RequestViewController {
                    let row = tableView.indexPathForSelectedRow!.row
                    
                    destCtrl.reqLocation    = locations[row]
                    destCtrl.reqRider       = usernames[row]
                    destCtrl.reqDistance    = distances[row]
                }
            }
            else {
                print("Asked for odd segue")
            }
        }
    }

    func refresh() {
        loadRequests()

        refresher.endRefreshing()
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

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let driver = locations[0]

        if PFUser.currentUser()?.objectId == nil {
            locationManager.stopUpdatingLocation()
        }

//        print(driver)

        let query = PFQuery(className: "DriverLocation")

        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)

        query.findObjectsInBackgroundWithBlock {
            (objects, error) -> Void in

            if error == nil {
                let objects = objects!

                if objects.count > 0 {
                    self.adding = false
//                    print("Updating location")

                    for request in objects {
                        request["location"] = PFGeoPoint(latitude: driver.coordinate.latitude, longitude: driver.coordinate.longitude)

                        request.saveInBackground()
                    }
                }
                else if !self.adding {
                    self.adding = true
//                    print("New record")

                    let locRecord = PFObject(className: "DriverLocation")

                    locRecord["username"] = PFUser.currentUser()?.username
                    locRecord["location"] = PFGeoPoint(latitude: driver.coordinate.latitude, longitude: driver.coordinate.longitude)

                    locRecord.saveInBackground()
                }
            }
            else {
                print(error?.localizedDescription)
            }
        }
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
