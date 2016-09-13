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
        self.view.layer.borderColor = UIColor.blueColor().CGColor
        self.view.layer.borderWidth = 4.0
    }

    @IBAction func buttonAction(sender: AnyObject) {
        if let viewController = storyboard?.instantiateViewControllerWithIdentifier("Red") {
            overlayViewController?.presentSecondaryViewController(viewController, animated: true, completion: nil)
        }
    }
}
