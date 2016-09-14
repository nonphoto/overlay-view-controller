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
}

struct Constants {
    struct TransitionConstants {
        static let PRESENTING_VIEW_ALPHA: CGFloat = 0.75
        static let PRESENTING_VIEW_SCALE: CGFloat = 0.95

        static let PRESENTED_VIEW_OFFSET: CGFloat = 44.0
        static let PRESENTED_VIEW_COMPACT_OFFSET: CGFloat = 32.0

        static let PRESENTATION_DURATION: NSTimeInterval = 0.6
        static let DISMISSAL_DURATION: NSTimeInterval = 0.3

        static let DISMISSAL_THRESHOLD: CGFloat = 0.3

        static let SPRING_DAMPING: CGFloat = 0.8
        static let SPRING_VELOCITY: CGFloat = 0.1
    }
}

class JLOverlayViewController: UIViewController {

    private var primaryViewController: UIViewController!
    private var secondaryViewController: UIViewController?

    private var isSecondaryViewControllerDeferred = false
    private var transitionPercentComplete: CGFloat = 0.0

    private var primaryHeightConstraint: NSLayoutConstraint!
    private var secondaryTopConstraint: NSLayoutConstraint!

    var hasSecondaryViewController: Bool {
        get {
            return secondaryViewController != nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        primaryViewController = storyboard?.instantiateViewControllerWithIdentifier("Blue")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.addChildViewController(primaryViewController)
        self.view.addSubview(primaryViewController.view)
        primaryViewController.didMoveToParentViewController(self)

        primaryViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint(item: primaryViewController.view, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: primaryViewController.view, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: primaryViewController.view, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1, constant: 0).active = true

        primaryHeightConstraint = NSLayoutConstraint(item: primaryViewController.view, attribute: .Height, relatedBy: .Equal, toItem: self.view, attribute: .Height, multiplier: 1, constant: 0)
        primaryHeightConstraint.active = true

    }

    func presentSecondaryViewController(viewController: UIViewController, animated: Bool, completion: ((Bool) -> Void)?) {
        if secondaryViewController == nil {
            secondaryViewController = viewController
            isSecondaryViewControllerDeferred = false
            self.addChildViewController(viewController)
            self.view.addSubview(viewController.view)

            let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_: )))
            gestureRecognizer.maximumNumberOfTouches = 1
            viewController.view.addGestureRecognizer(gestureRecognizer)

            viewController.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint(item: viewController.view, attribute: .Height, relatedBy: .Equal, toItem: self.view, attribute: .Height, multiplier: 1, constant: -Constants.TransitionConstants.PRESENTED_VIEW_OFFSET).active = true
            NSLayoutConstraint(item: viewController.view, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: viewController.view, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1, constant: 0).active = true

            secondaryTopConstraint = NSLayoutConstraint(item: viewController.view, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: self.view.bounds.height)
            secondaryTopConstraint.active = true

            self.view.layoutIfNeeded()

            let secondaryViewControllerOffset = Constants.TransitionConstants.PRESENTED_VIEW_OFFSET
            let primaryViewControllerScale = Constants.TransitionConstants.PRESENTING_VIEW_SCALE
            let primaryViewControllerAlpha = Constants.TransitionConstants.PRESENTING_VIEW_ALPHA

            UIView.animateWithDuration(
                Constants.TransitionConstants.PRESENTATION_DURATION,
                delay: 0,
                usingSpringWithDamping: Constants.TransitionConstants.SPRING_DAMPING,
                initialSpringVelocity: Constants.TransitionConstants.SPRING_VELOCITY,
                options: UIViewAnimationOptions.CurveLinear,
                animations: {
                    self.primaryViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, primaryViewControllerScale, primaryViewControllerScale)
                    self.primaryViewController.view.alpha = primaryViewControllerAlpha

                    self.secondaryTopConstraint.constant = secondaryViewControllerOffset
                    self.view.layoutIfNeeded()
                },
                completion: { _ in
                    viewController.didMoveToParentViewController(self)
                }
            )
        }
    }

    func deferSecondaryViewControllerAnimated(animated: Bool, completion: ((Bool) -> Void)?) {
        if self.secondaryViewController != nil {
            isSecondaryViewControllerDeferred = true

            UIView.animateWithDuration(
                Constants.TransitionConstants.DISMISSAL_DURATION,
                animations: {
                    self.primaryViewController.view.transform = CGAffineTransformIdentity
                    self.primaryViewController.view.alpha = 1
                    self.primaryHeightConstraint.constant = -Constants.TransitionConstants.PRESENTED_VIEW_OFFSET

                    self.secondaryTopConstraint.constant = self.view.bounds.height - Constants.TransitionConstants.PRESENTED_VIEW_OFFSET

                    self.view.layoutIfNeeded()
                },
                completion: nil
            )
        }
    }

    func restoreSecondaryViewControllerAnimated(animated: Bool, completion: ((Bool) -> Void)?) {
        if self.secondaryViewController != nil {
            isSecondaryViewControllerDeferred = false

            let secondaryViewControllerOffset = Constants.TransitionConstants.PRESENTED_VIEW_OFFSET
            let primaryViewControllerScale = Constants.TransitionConstants.PRESENTING_VIEW_SCALE
            let primaryViewControllerAlpha = Constants.TransitionConstants.PRESENTING_VIEW_ALPHA

            UIView.animateWithDuration(
                Constants.TransitionConstants.PRESENTATION_DURATION,
                delay: 0,
                usingSpringWithDamping: Constants.TransitionConstants.SPRING_DAMPING,
                initialSpringVelocity: Constants.TransitionConstants.SPRING_VELOCITY,
                options: UIViewAnimationOptions.CurveLinear,
                animations: {
                    self.primaryViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, primaryViewControllerScale, primaryViewControllerScale)
                    self.primaryViewController.view.alpha = primaryViewControllerAlpha
                    self.primaryHeightConstraint.constant = 0

                    self.secondaryTopConstraint.constant = secondaryViewControllerOffset

                    self.view.layoutIfNeeded()
                },
                completion: completion
            )
        }
    }

    func dismissSecondaryViewControllerAnimated(animated: Bool, completion: ((Bool) -> Void)?) {
        if let secondaryViewController = self.secondaryViewController {
            secondaryViewController.willMoveToParentViewController(nil)
            isSecondaryViewControllerDeferred = false

            UIView.animateWithDuration(
                Constants.TransitionConstants.DISMISSAL_DURATION,
                animations: {
                    self.primaryViewController.view.transform = CGAffineTransformIdentity
                    self.primaryViewController.view.alpha = 1
                    self.primaryHeightConstraint.constant = 0

                    self.secondaryTopConstraint.constant = self.view.bounds.height

                    self.view.layoutIfNeeded()
                },
                completion: {completed in
                    secondaryViewController.view.removeFromSuperview()
                    secondaryViewController.removeFromParentViewController()
                    self.secondaryViewController = nil

                    if let completion = completion {
                        completion(completed)
                    }
                }
            )
        }
    }

    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .Began:
            gestureRecognizer.setTranslation(CGPointMake(0, 0), inView: self.view)
            transitionPercentComplete = 0
        case .Changed:
            let translation = gestureRecognizer.translationInView(view)
            let percentage = translation.y / (self.view.bounds.height - (2 * Constants.TransitionConstants.PRESENTED_VIEW_OFFSET))
            if isSecondaryViewControllerDeferred {
                updateTransition(1 + percentage)
            }
            else {
                updateTransition(percentage)
            }
        case .Ended:
            if transitionPercentComplete > Constants.TransitionConstants.DISMISSAL_THRESHOLD {
                deferSecondaryViewControllerAnimated(true, completion: nil)
            }
            else {
                restoreSecondaryViewControllerAnimated(true, completion: nil)
            }
        default:
            dismissSecondaryViewControllerAnimated(true, completion: nil)
        }
    }

    func updateTransition(percentComplete: CGFloat) {
        self.transitionPercentComplete = percentComplete

        let targetScale: CGFloat = Constants.TransitionConstants.PRESENTING_VIEW_SCALE
        let scale = targetScale + (1 - targetScale) * percentComplete
        primaryViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)

        let targetAlpha: CGFloat = Constants.TransitionConstants.PRESENTING_VIEW_ALPHA
        let alpha = targetAlpha + (1 - targetAlpha) * percentComplete
        primaryViewController.view.alpha = alpha

        let offset = (self.view.bounds.height - (2 * Constants.TransitionConstants.PRESENTED_VIEW_OFFSET)) * percentComplete
        secondaryTopConstraint.constant = Constants.TransitionConstants.PRESENTED_VIEW_OFFSET + offset
    }
}
