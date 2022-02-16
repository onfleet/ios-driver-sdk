//
//  InitialViewController.swift
//  SampleApp
//
//  Created by Peter Stajger on 14/01/2021.
//

import UIKit
import RxSwift
import OnfleetDriver

final class InitialViewController : UIViewController, ActivityShowing {
    
    var activityAlert: UIAlertController?
    
    @IBOutlet private weak var phoneNumberField: UITextField!
    @IBOutlet private weak var passwordField: UITextField!
    
    private let session = DriverContext.shared.session
    private let bag = DisposeBag()
    
    private var sdkLogoutToken: NSObjectProtocol?
    private var appLogoutToken: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        verifyAuthentication()
        
        sdkLogoutToken = NotificationCenter.default.addObserver(forName: .sessionDidLogOut, object: nil, queue: nil) { [weak self] notification in
            if let reason = notification.userInfo?[SessionDidLogOutReasonKey] as? LogoutReason {
                self?.showAuthenticationFlow()
                self?.showAlert(title: "Logged Out", message: "You have been logged out (\(reason.description))", animated: true, okHandler: nil)
            }
        }
        
        appLogoutToken = NotificationCenter.default.addObserver(forName: Notification.Name("DutyViewControllerDidLogOutNotification"), object: nil, queue: nil) { [weak self] _ in
            print("user tapped logout button, attempting to log out...")
            self?.logOut(force: false)
        }
    }
    
    private func verifyAuthentication() {
        
        guard session.isAuthenticated else {
            return
        }
        
        print("driver is logged in")
        
        guard let pendingAccount = session.accounts.first(where: { $0.isPending }) else {
            print("no pending account found, moving to main application flow...")
            showMainApplicationFlow()
            return
        }
        
        print("pending account found, prompting for invitation response...")
        showAlertPrompt(title: "Pending Invitation", message: "You were invited to join \(pendingAccount.organizationName) as a driver.", action: UIAlertAction(title: "Accept", style: .default, handler: { [weak self] _ in
            self?.session.respondToInvitation(account: pendingAccount, response: .accept, completion: { result in
                switch result {
                case .success:
                    //there might be more pending accounts
                    self?.verifyAuthentication()
                case .failure(let error):
                    self?.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
                }
            })
        }), cancel: UIAlertAction(title: "Reject", style: .destructive, handler: { [weak self] _ in
            self?.session.respondToInvitation(account: pendingAccount, response: .reject, completion: { result in
                if case AccountInvitationResult.failure(let error) = result {
                    self?.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
                }
            })
        }), animated: true)
    }
    
    private func showMainApplicationFlow() {
        hideActivityIfNeeded { [weak self] in
            self?.performSegue(withIdentifier: "DutyViewControllerSegueId", sender: self)
        }
    }
    
    private func showAuthenticationFlow() {
        hideActivityIfNeeded { [weak self] in
            self?.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction private func attemptAuthentication() {
        
        guard let phoneNumber = phoneNumberField.text, !phoneNumber.isEmpty, let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "Failed", message: "Phone number or password is missing.", animated: true)
            return
        }
        
        let credentials = Credentials(phoneNumber: PhoneNumber(E164: phoneNumber, pretty: phoneNumber), password: password, usedAutoFill: false)
        session.login(credentials: credentials) { [weak self] (status) in
            switch status {
            case .busy(let operation):
                print("doing actual work")
                switch operation {
                case .loggingIn:
                    self?.showActivity("Authenticating...", animated: true)
                case .provisioning(let maxDuration):
                    self?.showActivity("Verifying Device...", "This operation can take up to \(seconds: Int(maxDuration), allowedUnits: [.second, .minute]).", animated: true)
                }
                
            case .idle:
                print("doing no work or waiting for user input")
                self?.hideActivityIfNeeded()
            case .waitingForAdminVerification:
                print("waiting for admin verification")
                self?.showActivity("Waiting for admin verification. This may take some time.", animated: true)
            }
        } completion: { [weak self] (result) in
            switch result {
            case .success:
                print("login successful")
                self?.verifyAuthentication()
                
            case .failure(let error):
                print("login failed: \(error.localizedDescription)")
                self?.showAlert(title: "Login Failed", message: error.localizedDescription, animated: true)
            }
        }
    }
    
    private func logOut(force: Bool) {
        print("logging out\(force == true ? " (by force)" : "")...")
        session.logout(force: force) {
            print("Logging out...")
        } completion: { [weak self] (result) in
            print("logout result: \(result)")
            if case Result.failure(let error) = result {
                self?.showAlertPrompt(title: "Logout Failed", message: error.localizedDescription, action: UIAlertAction(title: "Logout Anyway", style: .destructive, handler: { _ in
                    self?.logOut(force: true)
                }), animated: false)
            }
        }
    }
    
    @IBAction private func resetPassword() {
        
        guard let phoneNumber = phoneNumberField.text, !phoneNumber.isEmpty else {
            showAlert(title: "Password Reset Failed", message: "Enter phone number into the field and try again.", animated: true)
            return
        }
        showActivity("Resetting Password...", animated: true)
        session.resetPassword(for: PhoneNumber(E164: phoneNumber, pretty: phoneNumber)) { [weak self] result in
            print("reset password result: \(result)")
            switch result {
            case .success:
                self?.showAlert(title: "Password Reset", message: "You will receive SMS with new temp password. Use it to log in and you will be prompted for new password.", animated: true)
            case .failure(let error):
                self?.showAlert(title: "Password Reset Failed", message: error.localizedDescription, animated: true)
            }
        }
    }
}
