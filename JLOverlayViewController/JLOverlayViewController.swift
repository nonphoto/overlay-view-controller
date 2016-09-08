//
//  JLOverlayViewController.swift
//  JLOverlayViewController
//
//  Created by Jonas Luebbers on 9/2/16.
//  Copyright © 2016 JonasLuebbers. All rights reserved.
//

import UIKit

extension UIViewController {
    var overlayViewController: JLOverlayViewController? {
        get {
            var ancestor: UIViewController = self
            while !(ancestor is JLOverlayViewController) {
                if let parent = ancestor.parentViewController {
                    ancestor = parent
                }
                else {
                    return nil
                }
            }
            return ancestor as? JLOverlayViewController
        }
    }

    /**
    func unshowViewController(viewController: UIViewController) {
        if let presentingVC = targetViewControllerForAction(#selector(unshowViewController), sender: self) {
            presentingVC.unshowViewController(self)
        }
    }
     */
}

class JLOverlayViewController: UIViewController {

    let deferredViewControllerOffset: CGFloat = 44
    let primaryViewControllerAlpha: CGFloat = 0.5
    let primaryViewControllerScale: CGFloat = 0.9
    let secondaryViewControllerOffset: CGFloat = 44

    var primaryViewController: UIViewController!
    var secondaryViewController: UIViewController?

    var isSecondaryViewControllerDeferred = false
    var transitionPercentComplete: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        primaryViewController = storyboard?.instantiateViewControllerWithIdentifier("Blue")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.addChildViewController(primaryViewController)
        self.view.addSubview(primaryViewController.view)
        primaryViewController.didMoveToParentViewController(self)
        primaryViewController.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
    }

    func presentSecondaryViewController(viewController: UIViewController) {
        if secondaryViewController == nil {
            secondaryViewController = viewController
            isSecondaryViewControllerDeferred = false
            self.addChildViewController(viewController)
            self.view.addSubview(viewController.view)

            let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_: )))
            gestureRecognizer.maximumNumberOfTouches = 1
            viewController.view.addGestureRecognizer(gestureRecognizer)

            viewController.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height - secondaryViewControllerOffset)
            viewController.view.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, self.view.bounds.height)

            animateSecondaryViewControllerPresentation({ _ in
                viewController.didMoveToParentViewController(self)
            })
        }
    }

    func dismissSecondaryViewController() {
        if let viewController = secondaryViewController {
            viewController.willMoveToParentViewController(nil)
            animateSecondaryViewControllerDismissal({ _ in
                viewController.view.removeFromSuperview()
                viewController.removeFromParentViewController()
                self.secondaryViewController = nil
            })
        }
    }

    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .Began:
            gestureRecognizer.setTranslation(CGPointMake(0, 0), inView: self.view)
            transitionPercentComplete = 0
        case .Changed:
            let translation = gestureRecognizer.translationInView(view)
            let verticalTranslation = isSecondaryViewControllerDeferred ? translation.y + self.view.bounds.height - deferredViewControllerOffset : translation.y
            let percentage = verticalTranslation / CGRectGetHeight(view.bounds);
            updateTransition(percentage)
        case .Ended:
            if transitionPercentComplete > 0.5 {
                isSecondaryViewControllerDeferred = true
                animateSecondaryViewControllerDeferral(nil)
            }
            else {
                isSecondaryViewControllerDeferred = false
                animateSecondaryViewControllerPresentation(nil)
            }
        default:
            dismissSecondaryViewController()
        }
    }

    func updateTransition(percentComplete: CGFloat) {
        self.transitionPercentComplete = percentComplete

        let targetScale: CGFloat = primaryViewControllerScale
        let scale = targetScale + (1 - targetScale) * percentComplete
        primaryViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)

        let targetAlpha: CGFloat = primaryViewControllerAlpha
        let alpha = targetAlpha + (1 - targetAlpha) * percentComplete
        primaryViewController.view.alpha = alpha

        if let secondaryViewController = self.secondaryViewController {
            let offset = secondaryViewController.view.bounds.height * percentComplete
            secondaryViewController.view.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, self.secondaryViewControllerOffset + offset)
        }
    }

    func animateSecondaryViewControllerPresentation(completion: ((Bool) -> Void)?) {
        UIView.animateWithDuration(
            0.5,
            animations: {
                self.primaryViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, self.primaryViewControllerScale, self.primaryViewControllerScale)
                self.primaryViewController.view.alpha = self.primaryViewControllerAlpha

                self.secondaryViewController?.view.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, self.secondaryViewControllerOffset)
            },
            completion: completion
        )
    }

    func animateSecondaryViewControllerDeferral(completion: ((Bool) -> Void)?) {
        UIView.animateWithDuration(
            0.5,
            animations: {
                self.primaryViewController.view.transform = CGAffineTransformIdentity
                self.primaryViewController.view.alpha = 1

                self.secondaryViewController?.view.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, self.view.bounds.height - self.deferredViewControllerOffset)
            },
            completion: completion
        )
    }

    func animateSecondaryViewControllerDismissal(completion: ((Bool) -> Void)?) {
        UIView.animateWithDuration(
            0.5,
            animations: {
                self.primaryViewController.view.transform = CGAffineTransformIdentity
                self.primaryViewController.view.alpha = 1

                self.secondaryViewController?.view.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, self.view.bounds.height)
            },
            completion: completion
        )
    }
}
