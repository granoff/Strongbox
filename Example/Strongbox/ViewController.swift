//
//  ViewController.swift
//  Strongbox
//
//  Created by Mark Granoff on 10/09/2016.
//  Copyright (c) 2016 Mark Granoff. All rights reserved.
//

import UIKit
import Strongbox

class ViewController: UIViewController {

    @IBOutlet var textField: UITextField!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var fetchButton: UIButton!
    @IBOutlet var fetchedValueLabel: UILabel! {
        didSet {
            fetchedValueLabel.text = nil
        }
    }
    
    struct Constants {
        static let textFieldKey = "textFieldKey"
    }
    
    private var strongbox = Strongbox()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.becomeFirstResponder()
    }
    
    @IBAction func save() {
        _ = strongbox.archive(textField.text, key: Constants.textFieldKey)
    }
    
    @IBAction func fetch() {
        if let fetchedValue = strongbox.unarchive(objectForKey: Constants.textFieldKey) as? String {
            DispatchQueue.main.async {
                self.fetchedValueLabel.text = fetchedValue
            }
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        save()
        return true
    }
}
