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

class ViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var driverToggle: UISwitch!

    var indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

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
                    // Nothing for now
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

            PFUser.logInWithUsernameInBackground(username.texty, password: password.text, block: { (user, error) -> Void in

                if error == nil {
                    // Nothing for now
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





    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
