//
//  LegacyDutyViewController.swift
//  SampleApp
//
//  Created by Peter Stajger on 14/01/2021.
//

import UIKit
import CoreLocation

import OnfleetDriver

protocol LegacyLegacyDutyViewControllerDelegate {
    func dutyViewController(_ controller: LegacyDutyViewController, shouldLogOut sender: Any)
}

final class LegacyDutyViewController : UIViewController, ActivityShowing {
    
    var activityAlert: UIAlertController?
    @IBOutlet private weak var dutySwitch: UISwitch!
    
    private let session = DriverContext.shared.session
    private let driverManager = DriverContext.shared.legacyDriverManager
    private let location = DriverContext.shared.location
    private let bag = OnfleetDriver.DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = driverManager.legacyDriver?.organization.getName() ?? "Legacy"
        dutySwitch.addTarget(self, action: #selector(dutySwitchValueChanged(sender:)), for: .valueChanged)
        
        let dutyStatusDriver = driverManager.onDuty$.observe(on: .main)
        
        dutyStatusDriver.filter({ $0 == true }).subscribe({ [weak self] _ in
            self?.updateInterfaceOnDuty()
        }).disposed(by: bag)
        
        dutyStatusDriver.filter({ $0 == false }).subscribe({ [weak self] _ in
            self?.updateInterfaceOffDuty()
        }).disposed(by: bag)
        
        driverManager.onDuty$
            .observe(on: .main)
            .subscribe({ [weak self] value in self?.dutySwitch.isOn = value })
            .disposed(by: bag)
        
        location.isFullyAuthorized$
            .filter({ $0 == false })
            .subscribe({ [weak self] _ in
                guard let self = self else { return }
                guard self.driverManager.isOnDuty else { return }
                print("going off duty due to insufficient location permissions...")
                self.driverManager.setDutyStatus(goOnDuty: false) { result in
                    print("duty status result: \(result)")
                    self.hideActivityIfNeeded() {
                        if case Result.failure(let error) = result {
                            self.dutySwitch.isOn = false
                            self.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
                        } else {
                            self.showAlert(title: "Off Duty", message: "You went off duty due to insufficient location permissions", animated: true)
                        }
                    }
                }
            }).disposed(by: bag)
    }
    
    @objc private func dutySwitchValueChanged(sender: UISwitch) {
        
        if location.isFullyAuthorized == false && sender.isOn {
            CLLocationManager().requestAlwaysAuthorization()
        }
        
        print("chaning duty status due to user action...")
        self.showActivity("Going \(sender.isOn ? "on" : "off") duty...", animated: true)
        self.driverManager.setDutyStatus(goOnDuty: self.dutySwitch.isOn) { result in
            DispatchQueue.main.async(execute: {
                print("duty status result: \(result)")
                self.hideActivityIfNeeded() {
                    guard case let .failure(error) = result else {
                        return
                    }
                    sender.isOn = !sender.isOn
                    switch error {
                    case .locationPermissionsDenied:
                        self.showAlert(title: "Insufficient Location Access", message: "Our app requires Location Access 'Always' and Precise Location 'On' in order to work properly.", animated: true, okTitle: "Open Settings") { _ in
                            let settingsUrl = URL(string: UIApplication.openSettingsURLString)!
                            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                        }
                    default:
                        self.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
                    }
                }
            })
        }
    }
    
    @IBAction private func logOut(sender: Any) {
        
        guard driverManager.activeTask == nil else {
            showAlert(title: "Can't log out while there is an active task", message: nil, animated: true)
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name("DutyViewControllerDidLogOutNotification"), object: self)
    }
}

extension LegacyDutyViewController {
    
    private var tasksViewController: LegacyTasksViewController {
        return children[0] as! LegacyTasksViewController
    }
    
    private var legacyOffDutyViewController: LegacyOffDutyViewController {
        return children[1] as! LegacyOffDutyViewController
    }
    
    private func updateInterfaceOnDuty() {
        legacyOffDutyViewController.view.isHidden = true
        tasksViewController.view.isHidden = false
        tasksViewController.view.frame = view.bounds
        view.insertSubview(tasksViewController.view, aboveSubview: legacyOffDutyViewController.view)
    }
    
    private func updateInterfaceOffDuty() {
        tasksViewController.view.isHidden = true
        legacyOffDutyViewController.view.isHidden = false
        legacyOffDutyViewController.view.frame = view.bounds
        view.insertSubview(legacyOffDutyViewController.view, aboveSubview: tasksViewController.view)
    }
}
