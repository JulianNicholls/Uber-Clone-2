//
//  RequestViewController.swift
//  Schnell
//
//  Created by Julian Nicholls on 26/01/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RequestViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!

    var reqLocation = CLLocationCoordinate2DMake(0, 0)
    var reqRider    = "(None)"

    var locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        setMapCentre()
    }

    @IBAction func riderPressed(sender: AnyObject) {
        let query = PFQuery(className: "RideRequest")

        query.whereKey("username", equalTo: reqRider)

        query.findObjectsInBackgroundWithBlock({
            (objects, error) -> Void in

            if error == nil {
                let objects = objects as [PFObject]!

                for object in objects {
                    object["driverResponded"] = PFUser.currentUser()?.username
                    object.saveInBackground()
                }

                let reqCLLoc = CLLocation(latitude: self.reqLocation.latitude, longitude: self.reqLocation.longitude)

                CLGeocoder().reverseGeocodeLocation(reqCLLoc, completionHandler: {
                    (places, error) -> Void in

                    if error == nil {
                        if places!.count > 0 {
                            if let dest = places![0] as? CLPlacemark {
                                let mkpDest = MKPlacemark(placemark: dest)
                                let mapItem = MKMapItem(placemark: mkpDest)

                                mapItem.name = self.reqRider

                                let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]

                                mapItem.openInMapsWithLaunchOptions(launchOptions)
                            }
                            else {
                                print("Cannot downcast")
                            }
                        }
                        else {
                            print("No placemarks returned")
                        }
                    }
                    else {
                        print(error?.localizedDescription)
                    }
                })
            }
            else {
                print(error?.localizedDescription)
            }
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func setMapCentre() {
        let span    = MKCoordinateSpanMake(0.01, 0.01)
        let region  = MKCoordinateRegionMake(reqLocation, span)

        self.map.setRegion(region, animated: true)

        let ann = MKPointAnnotation()
        ann.coordinate = reqLocation
        ann.title = "'\(reqRider) Location"
        self.map.addAnnotation(ann)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
