/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var driverToggle: UISwitch!

    var indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.username.delegate = self
        self.password.delegate = self
    }

    override func viewDidAppear(animated: Bool) {
        if PFUser.currentUser()?.objectId != nil {
            performRelevantSegue()
        }
//        else {
//            print("no-one logged in")
//        }
    }

    @IBAction func signupPressed(sender: AnyObject) {
        let user = PFUser()

        if checkEntries() {
            displaySpinner()

            user.username = username.text
            user.password = password.text
            user["isDriver"] = driverToggle.on

            user.signUpInBackgroundWithBlock({
                (success, error) -> Void in

                self.indicator.stopAnimating()
                UIApplication.sharedApplication().endIgnoringInteractionEvents()

                if success {
                    self.performRelevantSegue()
                }
                else {
                    var errorMsg = "please try again later"

                    if let errorStr = error?.userInfo["error"] as? String {
                        errorMsg = errorStr
                    }

                    self.displayAlert(errorMsg, title: "There was a problem signing up")
                }
            })
        }

    }

    @IBAction func loginPressed(sender: AnyObject) {
        if checkEntries() {
            displaySpinner()

            PFUser.logInWithUsernameInBackground(username.text!, password: password.text!, block: { (user, error) -> Void in

                self.indicator.stopAnimating()
                UIApplication.sharedApplication().endIgnoringInteractionEvents()

                if error == nil {
                    self.performRelevantSegue()
                }
                else {
                    var errorMsg = "please try again later"

                    if let errorStr = error?.userInfo["error"] as? String {
                        errorMsg = errorStr
                    }

                    self.displayAlert(errorMsg, title: "There was a problem logging in")
                }
            })
        }
    }

    func performRelevantSegue() {
        if let isDriver = PFUser.currentUser()!["isDriver"] as? Bool {
            if isDriver {
                // Nothing for now
                print("Driver logged in")
            }
            else {
//                print("Rider logged in")
                performSegueWithIdentifier("loginRider", sender: self)
            }
        }
        else {
            print("Cockup on the isDriver front")
        }
    }

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
//        print("OK for segue: \(PFUser.currentUser()?.objectId)")

        return PFUser.currentUser()?.objectId != nil
    }

    func checkEntries() -> Bool {
        if username.text == "" || password.text == "" {
            displayAlert("You must enter both a username and password", title: "There was a problem")
            return false
        }

        return true
    }

    func displayAlert(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))

        self.presentViewController(alert, animated: true, completion: nil)
    }

    func displaySpinner() {
        indicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
        indicator.center = self.view.center
        indicator.hidesWhenStopped = true
        indicator.activityIndicatorViewStyle = .Gray

        self.view.addSubview(indicator)

        indicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }

    // Clicking outside the text fields will close the keyboard

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }

    // Pressing return will close the keyboard
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
