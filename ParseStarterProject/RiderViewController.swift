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
    var location = CLLocationCoordinate2D()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let user : CLLocation = locations[0]

        location = CLLocationCoordinate2DMake(user.coordinate.latitude, user.coordinate.longitude)
        let span = MKCoordinateSpanMake(0.005, 0.005)
        let region = MKCoordinateRegionMake(location, span)

        self.map.setRegion(region, animated: true)
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
        let call = PFObject(className: "RideRequest")

        call["riderId"]  = PFUser.currentUser()?.objectId
        call["location"] = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)

        call.saveInBackgroundWithBlock { (success, error) -> Void in
            if error == nil {
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
