//
//  RedViewController.swift
//  JLOverlayViewController
//
//  Created by Jonas Luebbers on 9/4/16.
//  Copyright © 2016 JonasLuebbers. All rights reserved.
//

import UIKit

class RedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func buttonAction(sender: AnyObject) {
        overlayViewController?.dismissSecondaryViewController()
    }
}
