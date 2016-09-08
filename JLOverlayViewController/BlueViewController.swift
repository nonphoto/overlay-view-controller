//
//  BlueViewController.swift
//  JLOverlayViewController
//
//  Created by Jonas Luebbers on 9/2/16.
//  Copyright © 2016 JonasLuebbers. All rights reserved.
//

import UIKit

class BlueViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func buttonAction(sender: AnyObject) {
        if let viewController = storyboard?.instantiateViewControllerWithIdentifier("Red") {
            overlayViewController?.presentSecondaryViewController(viewController)
        }
    }
}
