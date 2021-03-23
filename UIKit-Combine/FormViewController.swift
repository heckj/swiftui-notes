//
//  FormViewController.swift
//  UIKit-Combine
//
//  Created by Joseph Heck on 7/19/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import UIKit
import Combine

class FormViewController: UIViewController {

    @IBOutlet weak var value1_input: UITextField!
    @IBOutlet weak var value2_input: UITextField!
    @IBOutlet weak var value2_repeat_input: UITextField!
    @IBOutlet weak var submission_button: UIButton!
    @IBOutlet weak var value1_message_label: UILabel!
    @IBOutlet weak var value2_message_label: UILabel!

    @IBAction func value1_updated(_ sender: UITextField) {
        value1 = sender.text ?? ""
    }
    @IBAction func value2_updated(_ sender: UITextField) {
        value2 = sender.text ?? ""
    }
    @IBAction func value2_repeat_updated(_ sender: UITextField) {
        value2_repeat = sender.text ?? ""
    }

    @Published var value1: String = ""
    @Published var value2: String = ""
    @Published var value2_repeat: String = ""

    private var cancellableSet: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let isValidated1 = $value1
            .map { $0.count > 2 }
            .handleEvents(receiveOutput: {
                self.value1_message_label.text = $0 ? nil : "minimum of 3 characters required"
            })
        
        let isValidated2 = Publishers.CombineLatest($value2, $value2_repeat)
            .map { $0 == $1 && $0.count > 4 }
            .handleEvents(receiveOutput: {
                self.value2_message_label.text = $0 ? nil : "values must match and have at least 5 characters"
            })
        
        Publishers.CombineLatest(isValidated1, isValidated2)
            .map { $0 && $1 }
            .assign(to: \.isEnabled, on: submission_button)
            .store(in: &cancellableSet)
    }

}
