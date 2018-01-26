//
//  LoginViewController.swift
//  Chatster
//
//  Created  on 1/11/18.
//  Copyright © 2018 chat. All rights reserved.
//

import UIKit
import Alamofire
import SwiftKeychainWrapper

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    var activeField: UITextField?
    
    @IBAction func visitWebsiteButtonTapped(_ sender: Any) {
        redirectToURL(scheme: "https://mycarster.com")
    }
//
//    @IBAction func forgotPassTapped(_ sender: Any) {
//        redirectToURL(scheme: "https://mycarster.com/?page_id=27")
//    }
//    @IBAction func registerTapped(_ sender: Any) {
//        redirectToURL(scheme: "https://mycarster.com/?page_id=18")
//    }
    @IBAction func LoginButtonTapped(_ sender: Any) {
        
        login()
    
    }
    func login() {
        
        if emailField.text == ""{
            self.showAlert(title: "Username field is required!", message: "Please enter your username.")
            return
        }
        if passwordField.text == ""{
            self.showAlert(title: "Password field is required!", message: "Please enter your password.")
            return
        }
        startActivityIndicator()
        //        stopActivityIndicator()
        
        let parameters = [
            "user_login": emailField.text!,
            "user_pass": passwordField.text!
            ] as [String : Any]
        let url = "https://mycarster.com/webservices/login.php"
        Alamofire.request(
            URL(string: url)!,
            method: .post,
            parameters: parameters)
            .validate()
            .responseJSON { (response) -> Void in
                self.stopActivityIndicator()
                guard response.result.isSuccess else {
                    self.showAlert(title: "Login Failed", message: "Couldn't connect to server. \n Check your network connection and try again.")
                    return
                }
                guard let result = (response.result.value as? [String: Any]) else {
                    self.showAlert(title: "Login Failed", message: "Your did try to login with wrong user name or password.")
                    return
                }
                if result["Status"] as! String == "201"{
                    self.showAlert(title: "Login Failed", message: result["Message"] as! String);
                    KeychainWrapper.standard.removeObject(forKey: "carster_username")
                    KeychainWrapper.standard.removeObject(forKey: "carster_password")
                    return
                }
                KeychainWrapper.standard.set(self.emailField.text!, forKey: "carster_username")
                KeychainWrapper.standard.set(self.passwordField.text!, forKey: "carster_password")
                self.goToCapture()
        }
    }
    func goToCapture() {
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            if let navigator = self.navigationController {
                viewController.userName = emailField.text!
                viewController.password = passwordField.text!
                navigator.pushViewController(viewController, animated: true)
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        self.emailField.delegate = self
        self.passwordField.delegate = self
        
        let user_name: String? = KeychainWrapper.standard.string(forKey: "carster_username")
        let password :String? = KeychainWrapper.standard.string(forKey: "carster_password")
        
        if user_name != nil{
            self.emailField.text = user_name
            self.passwordField.text = password
            login()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar for current view controller
        self.navigationController?.isNavigationBarHidden = true
        registerForKeyboardNotifications()
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        deregisterFromKeyboardNotifications()
    }
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWasShown(notification: NSNotification){
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeField = self.activeField {
            if (!aRect.contains(activeField.frame.origin)){
                self.view.frame.origin.y -= keyboardSize!.height
            }
        }
    }
    @objc func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        self.view.frame.origin.y = 0
        self.view.endEditing(true)
    }

    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    func textFieldDidBeginEditing(_ textField: UITextField){
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        activeField = nil
    }
    
    func showAlert(title:String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(_ action: UIAlertAction) -> Void in }))
        self.present(alert, animated: true, completion: nil)
    }
    
}

