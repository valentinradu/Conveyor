//
//  ViewController.swift
//  TestProject
//
//  Created by Valentin Radu on 29/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        _ = NSLocalizedString("\(1.0)", comment:"")
        _ = String.localized.firstString
        _ = String.localized.fourthString
    }


}

