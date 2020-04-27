//
//  SettingViewController.swift
//  ActiDiabet
//
//  Created by 佟诗博 on 16/4/20.
//  Copyright © 2020 Shibo Tong. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {
    
    var notification: Notifications?
    
    @IBOutlet weak var scrollView: SettingScrollView!
    
    

    @IBOutlet weak var zipView: UIView!
    
    @IBOutlet weak var zipTextField: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = UIApplication.shared.delegate as? AppDelegate
        self.notification = delegate?.notification
        setupUI()
        
        // Do any additional setup after loading the view.
    }
    
    func setupUI() {
        modifyView(view: zipView)
        modifyView(view: saveButton)
        setupSavedData()
    }
    
    func setupSavedData() {
        let zip = UserDefaults.standard.value(forKey: "zipcode") as? String
        zipTextField.text = zip
        scrollView.vcdelegate = self
    }
    
    
    func modifyView(view: UIView) {
        view.layer.cornerRadius = 20
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }

    @IBAction func saveSettings(_ sender: Any) {
        let zip = zipTextField.text
        if checkzipcode(zip: zip ?? "") {
            UserDefaults.standard.set(zip, forKey: "zipcode")
            print("set zip code to \(zip)")
        } else {
            showAlert(message: "Please enter a valid zip code", title: "Zip Code Error")
            return
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func checkzipcode(zip: String) -> Bool {
        if zip.count == 4 && zip.first == "3" {
            //self.zipCode = zip
            return true
        } else {
            return false
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func showAlert(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }

}

extension SettingViewController: ResignTextFieldDelegate {
    func resignAll() {
        zipTextField.resignFirstResponder()
    }
}

protocol ResignTextFieldDelegate {
    func resignAll()
}

class SettingScrollView: UIScrollView {
    
    var vcdelegate: ResignTextFieldDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        vcdelegate?.resignAll()
    }
}
