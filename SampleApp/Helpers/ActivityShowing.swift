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
    
    func showActivity(_ title: String, _ message: String? = nil, animated: Bool) {
        if activityAlert == nil {
            activityAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        }
        if let alert = activityAlert, alert.presentingViewController == nil {
            if let modal = self.presentedViewController {
                modal.present(alert, animated: animated, completion: nil)
            } else {
                self.present(alert, animated: animated, completion: nil)
            }
        }
        activityAlert?.title = title
        activityAlert?.message = message
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
    
    func showNewPasswordPrompt(username: String?, completion: @escaping (_ text: String?, _ isCancelled: Bool) -> Void) {
        hideActivityIfNeeded { [weak self] in
            let alert = Self.makeNewPasswordPicker(username: username, completion: completion)
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    private static func makeNewPasswordPicker(username: String?, completion: @escaping (_ text: String?, _ isCancelled: Bool) -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title:      "Choose a new password",
            message:    "Password should have at least 5 characters",
            preferredStyle: .alert)
        
        //this would enable new password suggestion, but we need to have there username text input for iOS heuristicts to work (verify this on recent OSes).
        alert.addTextField { textField in
            textField.textContentType = .username
            textField.text = username
            textField.isEnabled = false
        }
        
        alert.addTextField { textField in
            textField.textContentType = .newPassword
            textField.passwordRules = UITextInputPasswordRules(descriptor: "minlenght: 5")
            textField.placeholder = "Password"
            textField.keyboardAppearance = .alert
            textField.keyboardType = .default
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completion(nil, true)
        }))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] _ in
            if let password = alert?.textFields?.first(where: { $0.textContentType == .newPassword })?.text, password.isEmpty == false {
                completion(password, false)
            }
            else {
                completion(nil, true)
            }
        }))
        alert.preferredAction = alert.actions.last
        return alert
    }
    
    func showSMSVerificationPrompt(completion: @escaping (_ text: String?, _ isCancelled: Bool) -> Void) {
        hideActivityIfNeeded { [weak self] in
            let alert = Self.makeSMSCodePicker(completion: completion)
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    static func makeSMSCodePicker(completion: @escaping (_ text: String?, _ isCancelled: Bool) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: "Please enter the received SMS code.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.textContentType = .oneTimeCode
            textField.keyboardAppearance = .alert
            textField.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completion(nil, true)
        }))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] _ in
            if let textFieldText = alert?.textFields?.first?.text, textFieldText.isEmpty == false {
                completion(textFieldText, false)
            }
            else {
                completion(nil, true)
            }
        }))
        alert.preferredAction = alert.actions.last
        return alert
    }
    
}
