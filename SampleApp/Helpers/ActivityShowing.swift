//
//  ActivityShowing.swift
//  SampleApp
//
//  Created by Peter Stajger on 29/04/2021.
//

import UIKit

protocol ActivityShowing : UIViewController {
    var activityAlert: UIAlertController? { get set }
}

extension ActivityShowing {
    
    func showActivity(_ title: String, animated: Bool) {
        if activityAlert == nil {
            activityAlert = UIAlertController(title: nil, message: title, preferredStyle: .alert)
        }
        if let alert = activityAlert, alert.presentingViewController == nil {
            present(alert, animated: animated, completion: nil)
        }
        activityAlert?.message = title
    }
    
    func hideActivity(completion: (()->Void)? = nil) {
        if let alert = activityAlert {
            alert.dismiss(animated: false, completion: completion)
        }
        else {
            completion?()
        }
    }
    
    func showAlert(title: String?, message: String?, animated: Bool, okHandler: ((UIAlertAction) -> Void)? = nil) {
        hideActivity { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: okHandler))
            self?.present(alert, animated: animated, completion: nil)
        }
    }
    
    func showAlertPrompt(title: String?, message: String?, action: UIAlertAction, cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil), animated: Bool) {
        hideActivity { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(cancel)
            alert.addAction(action)
            alert.preferredAction = action
            self?.present(alert, animated: animated, completion: nil)
        }
    }
}
