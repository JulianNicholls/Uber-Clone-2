//
//  RiderViewController.swift
//  Schnell
//
//  Created by Julian Nicholls on 25/01/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callButton: UIButton!

    var locationManager = CLLocationManager()
    var location        = CLLocationCoordinate2D()

    var requestsPresent = 0

    var latDelta  = 0.003
    var longDelta = 0.003

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        setCallState()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let user : CLLocation = locations[0]
        let driverPin = MKPointAnnotation()

        location = CLLocationCoordinate2DMake(user.coordinate.latitude, user.coordinate.longitude)

        let reqQuery = PFQuery(className: "RideRequest")

        reqQuery.whereKey("username", equalTo: PFUser.currentUser()!.username!)

        reqQuery.findObjectsInBackgroundWithBlock {
            (objects, error) -> Void in

            if error ==  nil {
                let objects = objects!

                for request in objects {
                    if let driver = request["driverResponded"] {
                        let locQuery = PFQuery(className: "DriverLocation")

                        locQuery.whereKey("username", equalTo: driver)

                        locQuery.findObjectsInBackgroundWithBlock({
                            (objects, error) -> Void in

                            if error == nil {
                                let objects = objects!

                                let driverLoc = objects[0]["location"]
                                let driverCLL = CLLocation(latitude: driverLoc.latitude, longitude: driverLoc.longitude)
                                let distance  = user.distanceFromLocation(driverCLL)
                                let distkm = round(Double(distance / 100.0)) / 10.0

                                self.callButton.setTitle("\(driver) is \(distkm)km away", forState: .Normal)

                                driverPin.coordinate = CLLocationCoordinate2DMake(driverLoc.latitude, driverLoc.longitude)
                                driverPin.title = "\(driver) Location"

                                let distLat  = abs(driverLoc.latitude - self.location.latitude)
                                let distLong = abs(driverLoc.longitude - self.location.longitude)

                                self.latDelta  = distLat * 2 + 0.01
                                self.longDelta = distLong * 2 + 0.01
                            }
                            else {
                                print(error?.localizedDescription)
                            }
                        })
                    }
                    else {
                        print("request present, no driver")
                    }
                }
            }
            else {
                print(error?.localizedDescription)
            }
        }

        let span    = MKCoordinateSpanMake(latDelta, longDelta)
        let region  = MKCoordinateRegionMake(location, span)

        self.map.setRegion(region, animated: true)

        let userPin = MKPointAnnotation()

        userPin.coordinate = location
        userPin.title = "You are here!"

        map.removeAnnotations(map.annotations)
        map.addAnnotation(userPin)
        if driverPin.title != "" {
            map.addAnnotation(driverPin)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "logoutRider" {
            PFUser.logOut()
        }
        else {
            print("Asked for odd segue")
        }
    }
    
    @IBAction func callPressed(sender: AnyObject) {
        if requestsPresent > 0 {
            cancelCall()
        }
        else {
            let call = PFObject(className: "RideRequest")

            call["username"] = PFUser.currentUser()?.username
            call["location"] = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)

            // In a real app, you'd make a role that covered rider and driver and set
            // read and write access to them exclusively
            let acl = PFACL()
            acl.publicReadAccess = true
            acl.publicWriteAccess = true

            call.ACL = acl
                
            call.saveInBackgroundWithBlock { (success, error) -> Void in
                if error == nil {
                    self.setCallState()
                    self.displayAlert("Your ride request has been made", title: "Schnell")
                }
                else {
                    var errorMsg = "Please try again shortly"

                    if let errorStr = error?.userInfo["error"] as? String {
                        errorMsg = errorStr
                    }

                    self.displayAlert(errorMsg, title: "There was a problem")
                }
            }
        }
    }

    func setCallState() {
        let query = PFQuery(className: "RideRequest")

        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)

        query.findObjectsInBackgroundWithBlock {
            (objects, error) -> Void in

            if error == nil {
                self.requestsPresent = (objects?.count)!

                if self.requestsPresent == 0 {
                    self.callButton.setTitle("Call a SchnellWagen", forState: .Normal)
                }
                else {
                    self.callButton.setTitle("Cancel SchnellWagen", forState: .Normal)
                }
            }
            else {
                print(error?.localizedDescription)
            }
        }
    }

    func cancelCall() {
        let query = PFQuery(className: "RideRequest")

        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)

        query.findObjectsInBackgroundWithBlock({
            (objects, error) -> Void in

            if error != nil {
                var errorMsg = "Please try again shortly"

                if let errorStr = error?.userInfo["error"] as? String {
                    errorMsg = errorStr
                }

                self.displayAlert(errorMsg, title: "There was a problem cancelling your ride request")
            }
            else {
                let objects = objects as [PFObject]!

                for object in objects {
                    object.deleteInBackground()
                }

                self.setCallState()
            }
        })
    }

    func displayAlert(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))

        self.presentViewController(alert, animated: true, completion: nil)
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
