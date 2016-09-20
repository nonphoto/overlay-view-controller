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
    private var deferredViewControllerBar: UINavigationBar?

    private var isSecondaryViewControllerDeferred = false
    private var transitionPercentComplete: CGFloat = 0.0

    private var primaryPresentedHeightConstraint: NSLayoutConstraint!
    private var primaryDismissedHeightConstraint: NSLayoutConstraint!

    private var secondaryHeightConstraint: NSLayoutConstraint?
    private var secondaryPresentedTopConstraint: NSLayoutConstraint?
    private var secondaryDeferredTopConstraint: NSLayoutConstraint?
    private var secondaryTransitionTopConstraint: NSLayoutConstraint?

    private var barHeightConstraint: NSLayoutConstraint?

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
        primaryViewController.view.topAnchor.constraintEqualToAnchor(self.view.topAnchor).active = true
        primaryViewController.view.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor).active = true
        primaryViewController.view.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor).active = true
        primaryPresentedHeightConstraint = primaryViewController.view.heightAnchor.constraintEqualToAnchor(self.view.heightAnchor, constant: -Constants.TransitionConstants.PRESENTED_VIEW_OFFSET)
        primaryDismissedHeightConstraint = primaryViewController.view.heightAnchor.constraintEqualToAnchor(self.view.heightAnchor)
        primaryDismissedHeightConstraint.active = true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        let regularOffset = Constants.TransitionConstants.PRESENTED_VIEW_OFFSET
        let compactOffset = Constants.TransitionConstants.PRESENTED_VIEW_COMPACT_OFFSET
        let offset = newCollection.verticalSizeClass == .Compact ? compactOffset : regularOffset

        self.primaryPresentedHeightConstraint.constant = -offset
        self.secondaryHeightConstraint?.constant = -offset
        self.secondaryPresentedTopConstraint?.constant = offset
        self.secondaryDeferredTopConstraint?.constant = -offset
        self.barHeightConstraint?.constant = offset
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

            let regularOffset = Constants.TransitionConstants.PRESENTED_VIEW_OFFSET
            let compactOffset = Constants.TransitionConstants.PRESENTED_VIEW_COMPACT_OFFSET
            let offset = self.view.traitCollection.verticalSizeClass == .Compact ? compactOffset : regularOffset
            let scale = Constants.TransitionConstants.PRESENTING_VIEW_SCALE
            let alpha = Constants.TransitionConstants.PRESENTING_VIEW_ALPHA

            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor).active = true
            viewController.view.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor).active = true
            secondaryHeightConstraint = viewController.view.heightAnchor.constraintEqualToAnchor(self.view.heightAnchor, constant: -offset)
            secondaryHeightConstraint!.active = true
            secondaryPresentedTopConstraint = viewController.view.topAnchor.constraintEqualToAnchor(self.view.topAnchor, constant: offset)
            secondaryDeferredTopConstraint = viewController.view.topAnchor.constraintEqualToAnchor(self.view.bottomAnchor, constant: -offset)
            secondaryTransitionTopConstraint = viewController.view.topAnchor.constraintEqualToAnchor(self.view.topAnchor, constant: self.view.bounds.height)
            secondaryTransitionTopConstraint!.active = true

            self.view.layoutIfNeeded()

            let navigationBar = UINavigationBar()
            viewController.view.addSubview(navigationBar)
            let navigationItem = UINavigationItem(title: "Secondary")
            navigationBar.pushNavigationItem(navigationItem, animated: false)
            navigationBar.alpha = 0
            navigationBar.translatesAutoresizingMaskIntoConstraints = false

            navigationBar.topAnchor.constraintEqualToAnchor(viewController.view.topAnchor).active = true
            navigationBar.leadingAnchor.constraintEqualToAnchor(viewController.view.leadingAnchor).active = true
            navigationBar.trailingAnchor.constraintEqualToAnchor(viewController.view.trailingAnchor).active = true
            barHeightConstraint = navigationBar.heightAnchor.constraintEqualToConstant(offset)
            barHeightConstraint!.active = true


            self.deferredViewControllerBar = navigationBar

            self.view.layoutIfNeeded()

            UIView.animateWithDuration(
                Constants.TransitionConstants.PRESENTATION_DURATION,
                delay: 0,
                usingSpringWithDamping: Constants.TransitionConstants.SPRING_DAMPING,
                initialSpringVelocity: Constants.TransitionConstants.SPRING_VELOCITY,
                options: UIViewAnimationOptions.CurveLinear,
                animations: {
                    self.primaryViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)
                    self.primaryViewController.view.alpha = alpha
                    self.primaryDismissedHeightConstraint.active = false
                    self.primaryPresentedHeightConstraint.active = true

                    self.secondaryTransitionTopConstraint?.active = false
                    self.secondaryPresentedTopConstraint?.active = true

                    self.view.layoutIfNeeded()
                },
                completion: { _ in
                    viewController.didMoveToParentViewController(self)
                }
            )
        }
    }

    func deferSecondaryViewControllerAnimated(animated: Bool, completion: ((Bool) -> Void)?) {
        if self.secondaryViewController !=  nil {
            isSecondaryViewControllerDeferred = true

            UIView.animateWithDuration(
                Constants.TransitionConstants.DISMISSAL_DURATION,
                animations: {
                    self.deferredViewControllerBar?.alpha = 1

                    self.primaryViewController.view.transform = CGAffineTransformIdentity
                    self.primaryViewController.view.alpha = 1

                    self.secondaryTransitionTopConstraint?.active = false
                    self.secondaryPresentedTopConstraint?.active = false
                    self.secondaryDeferredTopConstraint?.active = true

                    self.view.layoutIfNeeded()
                },
                completion: completion
            )
        }
    }

    func restoreSecondaryViewControllerAnimated(animated: Bool, completion: ((Bool) -> Void)?) {
        if self.secondaryViewController != nil {
            isSecondaryViewControllerDeferred = false

            let scale = Constants.TransitionConstants.PRESENTING_VIEW_SCALE
            let alpha = Constants.TransitionConstants.PRESENTING_VIEW_ALPHA

            UIView.animateWithDuration(
                Constants.TransitionConstants.PRESENTATION_DURATION,
                delay: 0,
                usingSpringWithDamping: Constants.TransitionConstants.SPRING_DAMPING,
                initialSpringVelocity: Constants.TransitionConstants.SPRING_VELOCITY,
                options: UIViewAnimationOptions.CurveLinear,
                animations: {
                    self.deferredViewControllerBar?.alpha = 0

                    self.primaryViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)
                    self.primaryViewController.view.alpha = alpha

                    self.secondaryTransitionTopConstraint?.active = false
                    self.secondaryDeferredTopConstraint?.active = false
                    self.secondaryPresentedTopConstraint?.active = true

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
                    self.primaryPresentedHeightConstraint.active = false
                    self.primaryDismissedHeightConstraint.active = true

                    self.secondaryPresentedTopConstraint?.active = false
                    self.secondaryDeferredTopConstraint?.active = false
                    self.secondaryTransitionTopConstraint?.active = true
                    self.secondaryTransitionTopConstraint?.constant = self.view.bounds.height

                    self.view.layoutIfNeeded()
                },
                completion: {completed in
                    secondaryViewController.view.removeFromSuperview()
                    secondaryViewController.removeFromParentViewController()

                    self.secondaryViewController = nil
                    self.deferredViewControllerBar = nil

                    self.secondaryPresentedTopConstraint = nil
                    self.secondaryDeferredTopConstraint = nil
                    self.secondaryTransitionTopConstraint = nil
                    self.barHeightConstraint = nil

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
        secondaryTransitionTopConstraint?.constant = Constants.TransitionConstants.PRESENTED_VIEW_OFFSET + offset
        
        self.secondaryPresentedTopConstraint?.active = false
        self.secondaryDeferredTopConstraint?.active = false
        self.secondaryTransitionTopConstraint?.active = true
        
        self.view.layoutIfNeeded()
    }
}
