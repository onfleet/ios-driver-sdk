//
//  DutyViewController.swift
//  SampleApp
//
//  Created by Peter Stajger on 14/01/2021.
//

import UIKit
import OnfleetDriver
import RxSwift
import RxCocoa

protocol DutyViewControllerDelegate {
    func dutyViewController(_ controller: DutyViewController, shouldLogOut sender: Any)
}

final class DutyViewController : UIViewController, ActivityShowing {
    
    var activityAlert: UIAlertController?
    @IBOutlet private weak var dutySwitch: UISwitch!
    
    private let session = DriverContext.shared.session
    private let driverManager = DriverContext.shared.driverManager
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = driverManager.driver?.organization.getName()
        dutySwitch.addTarget(self, action: #selector(dutySwitchValueChanged(sender:)), for: .valueChanged)
        
        let dutyStatusDriver = driverManager.onDuty$.observable.asDriver(onErrorJustReturn: false)
        dutyStatusDriver.filter({ $0 == true }).drive(onNext: { [weak self] _ in
            self?.updateInterfaceOnDuty()
        }).disposed(by: bag)
        dutyStatusDriver.filter({ $0 == false }).drive(onNext: { [weak self] _ in
            self?.updateInterfaceOffDuty()
        }).disposed(by: bag)
        
        driverManager.onDuty$.observable.asDriver(onErrorJustReturn: false)
            .drive(self.dutySwitch.rx.isOn)
            .disposed(by: bag)
    }
    
    @objc private func dutySwitchValueChanged(sender: UISwitch) {
        print("chaning duty status...")
        showActivity("Going \(sender.isOn ? "on" : "off") duty...", animated: true)
        driverManager.setDutyStatus(goOnDuty: dutySwitch.isOn) { [weak self] (result) in
            print("duty status result: \(result)")
            self?.hideActivity() {
                if case Result.failure(let error) = result {
                    sender.isOn = !sender.isOn
                    self?.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
                }
            }
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

extension DutyViewController {
    
    private var tasksViewController: TasksViewController {
        return children[0] as! TasksViewController
    }
    
    private var offDutyViewController: OffDutyViewController {
        return children[1] as! OffDutyViewController
    }
    
    private func updateInterfaceOnDuty() {
        //dutySwitch.isOn = true
        offDutyViewController.view.isHidden = true
        tasksViewController.view.isHidden = false
        tasksViewController.view.frame = view.bounds
        view.insertSubview(tasksViewController.view, aboveSubview: offDutyViewController.view)
    }
    
    private func updateInterfaceOffDuty() {
        //dutySwitch.isOn = false
        tasksViewController.view.isHidden = true
        offDutyViewController.view.isHidden = false
        offDutyViewController.view.frame = view.bounds
        view.insertSubview(offDutyViewController.view, aboveSubview: tasksViewController.view)
    }
}
