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

        location = CLLocationCoordinate2DMake(user.coordinate.latitude, user.coordinate.longitude)
        let span = MKCoordinateSpanMake(0.003, 0.003)
        let region = MKCoordinateRegionMake(location, span)

        self.map.setRegion(region, animated: true)

        let ann = MKPointAnnotation()

        ann.coordinate = location
        ann.title = "You are here!"

        map.removeAnnotations(map.annotations)
         map.addAnnotation(ann)
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
