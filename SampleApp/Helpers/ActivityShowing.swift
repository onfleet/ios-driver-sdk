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
            if let modal = self.presentedViewController {
                modal.present(alert, animated: animated, completion: nil)
            } else {
                self.present(alert, animated: animated, completion: nil)
            }
        }
        activityAlert?.message = title
    }
    
    func hideActivityIfNeeded(completion: (()->Void)? = nil) {
        if let alert = activityAlert {
            alert.dismiss(animated: false, completion: completion)
        }
        else {
            completion?()
        }
    }
    
    func showAlert(title: String?, message: String?, animated: Bool, okTitle: String = "OK", okHandler: ((UIAlertAction) -> Void)? = nil) {
        hideActivityIfNeeded { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: okTitle, style: .cancel, handler: okHandler))
            self?.present(alert, animated: animated, completion: nil)
        }
    }
    
    func showAlertPrompt(title: String?, message: String?, action: UIAlertAction, cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil), animated: Bool) {
        hideActivityIfNeeded { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(cancel)
            alert.addAction(action)
            alert.preferredAction = action
            if let self = self {
                if let modal = self.presentedViewController {
                    modal.present(alert, animated: animated, completion: nil)
                } else {
                    self.present(alert, animated: animated, completion: nil)
                }
            }
        }
    }
}
