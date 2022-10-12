//
//  TaskViewController.swift
//  SampleApp
//
//  Created by Peter Stajger on 29/04/2021.
//

import UIKit

import OnfleetDriver

class TaskViewController : UITableViewController, ActivityShowing {
    
    var driverManager: DriverManaging!
    var task: Task!
    
    private var bag = OnfleetDriver.DisposeBag()
    
    var activityAlert: UIAlertController?
    
    @IBOutlet weak var stateActiveLabel: UILabel!
    @IBOutlet weak var stateSelfAssignmentLabel: UILabel!
    @IBOutlet weak var stateSelfAssignedLabel: UILabel!
    
    @IBOutlet weak var recipientNameLabel: UILabel!
    @IBOutlet weak var recipientPhoneLabel: UILabel!
    @IBOutlet weak var recipientNotesLabel: UILabel!
    
    @IBOutlet weak var destinationLocationLabel: UILabel!
    @IBOutlet weak var destinationAddressLabel: UILabel!
    @IBOutlet weak var destinationNotesLabel: UILabel!
    
    @IBOutlet weak var detailsQuantityLabel: UILabel!
    @IBOutlet weak var detailsTaskTypeLabel: UILabel!
    @IBOutlet weak var detailsCompleteAfterLabel: UILabel!
    @IBOutlet weak var detailsCompleteBeforeLabel: UILabel!
    @IBOutlet weak var detailsNotesLabel: UILabel!
    
    @IBOutlet weak var requirementsSigntureLabel: UILabel!
    @IBOutlet weak var requirementsNotesLabel: UILabel!
    @IBOutlet weak var requirementsPhotoLabel: UILabel!
    @IBOutlet weak var requirementsMinimumAgeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        task.changeObservableWithChildren
            .observe(on: .main)
            .subscribe { _ in print("task changed with children") }
            .disposed(by: bag)
        
        task.changeObservable
            .observe(on: .main)
            .subscribe { _ in print("task changed") }
            .disposed(by: bag)
        
        // when task is deleted or unassigned by a dispatcher
        task.deleteObservable
            .observe(on: .main)
            .subscribe({ [weak self] _ in
                print("task deleted or unassigned")
                self?.showAlert(title: "Task Deleted or Unassinged", message: nil, animated: true, okHandler: { _ in
                    self?.navigationController?.popViewController(animated: true)
                })
            }).disposed(by: bag)

        // when set off duty for some reason
        driverManager.onDuty$.filter({ $0 == false })
            //.debug("driver went off duty", trimOutput: true)
            .subscribe({ [weak self] _ in
            self?.showAlert(title: "Driver Off Duty", message: nil, animated: true, okHandler: { _ in
                self?.navigationController?.popViewController(animated: true)
            })
        }).disposed(by: bag)
        
        // title is task's short id
        task.shortId
            .map({ "#\($0)" })
            .observe(on: .main)
            .subscribe({ [weak self] value in self?.navigationItem.title = value })
            .disposed(by: bag)

        // update action button according to task state (start, complete, claim).
        Observable.combineLatest(
            task.isActive,
            task.isSelfAssignable,
            resultSelector: { return ($0, $1) })
            .observe(on: .main)
            .subscribe({ [weak self] isActive, isSelfAssignable in
                let eligibleForActivation = !isActive && !isSelfAssignable
                let eligibleForSelfAssignment = isSelfAssignable && !isActive
                let eligibleForCompletion = isActive
                if eligibleForActivation {
                    self?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .done, target: self, action: #selector(TaskViewController.startTask(sender:)))
                } else if eligibleForSelfAssignment {
                    self?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Claim", style: .done, target: self, action: #selector(TaskViewController.selfAssignTask(sender:)))
                } else if eligibleForCompletion {
                    self?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Complete", style: .done, target: self, action: #selector(TaskViewController.completeTask(sender:)))
                }
            }).disposed(by: bag)
        
        // when task is started
        task.isActive
            .map({ $0 == true ? "active" : "inactive"  })
            .observe(on: .main)
            .subscribe({ [weak self] value in self?.stateActiveLabel.text = value })
            .disposed(by: bag)
        
        // when task is started
        task.isActive
            .skip(1)
            .observe(on: .main)
            .subscribe({ [weak self] _ in self?.highlightView(self!.stateActiveLabel, animated: true)
        }).disposed(by: bag)
        
        // when task is assigned or unassigned to a team, instead of the driver we flash background
        task.isSelfAssignable
            .map({ String(describing: $0) })
            .subscribe({ [weak self] value in self?.stateSelfAssignmentLabel.text = value })
            .disposed(by: bag)
        
        // highlight cell on change
        task.isSelfAssignable
            .skip(1)
            .observe(on: .main)
            .subscribe({ [weak self] _ in self?.highlightView(self!.stateSelfAssignmentLabel, animated: true)
        }).disposed(by: bag)
        
        // when a task is self-assigned by the driver
        task.isSelfAssigned
            .map({ String(describing: $0) })
            .observe(on: .main)
            .subscribe({ [weak self] value in self?.stateSelfAssignedLabel.text = value })
            .disposed(by: bag)
        
        // highlight cell on change
        task.isSelfAssigned
            .skip(1)
            .observe(on: .main)
            .subscribe({ [weak self] _ in self?.highlightView(self!.stateSelfAssignedLabel, animated: true)
        }).disposed(by: bag)
        
        // destination address
        task.destination
            .map({ $0.getAddress().formattedShortAddress })
            .observe(on: .main)
            .subscribe({ [weak self] value in self?.destinationAddressLabel.text = value })
            .disposed(by: bag)
        
        // destination address
        task.destination
            .map({ String(describing: $0.getLocation().formattedLocation) })
            .observe(on: .main)
            .subscribe({ [weak self] value in self?.destinationLocationLabel.text = value })
            .disposed(by: bag)
        
        // highlight cell on change
        task.destination
            .skip(1)
            .observe(on: .main)
            .subscribe({ [weak self] _ in
            self?.highlightView(self!.destinationLocationLabel, animated: true)
            self?.highlightView(self!.destinationAddressLabel, animated: true)
        }).disposed(by: bag)
  
        // observe recipient name & phone
        //TODO: this does not work
        task.recipients
            .observe(on: .main)
            .subscribe({ [weak self] recipients in
            self?.recipientNameLabel.text = recipients.models.first?.getName() ?? "No Recipient"
            self?.recipientPhoneLabel.text = recipients.models.first?.getPhone() ?? "No Phone"
        }).disposed(by: bag)
        
        // we can only observe requirements as a whole, not each property individually
        task.requirements
            .observe(on: .main)
            .subscribe({ [weak self] requirements in
            self?.requirementsSigntureLabel.text = requirements.signature ? "required" : "optional"
            self?.requirementsPhotoLabel.text = requirements.photo ? "required" : "optional"
            self?.requirementsNotesLabel.text = requirements.notes ? "required" : "optional"
            self?.requirementsMinimumAgeLabel.text = requirements.minimumAge != nil ? "\(requirements.minimumAge!)+" : "none"
        }).disposed(by: bag)
        
        // quantity cell on change
        task.quantity
            .map({ $0.formattedDecimal() })
            .observe(on: .main)
            .subscribe({ [weak self] value in self?.detailsQuantityLabel.text = value })
            .disposed(by: bag)
        
        // highlight cell on change
        task.quantity
            .skip(1)
            .observe(on: .main)
            .subscribe({ [weak self] _ in self?.highlightView(self!.detailsQuantityLabel, animated: true)
        }).disposed(by: bag)
        
        // pickup or dropoff task type
        task.pickupTask
            .map({ $0 == true ? "Pickup" : "Dropoff" })
            .subscribe({ [weak self] value in self?.detailsTaskTypeLabel.text = value })
            .disposed(by: bag)
        
        // highlight cell on change
        task.pickupTask
            .skip(1)
            .observe(on: .main)
            .subscribe({ [weak self] _ in self?.highlightView(self!.detailsTaskTypeLabel, animated: true)
        }).disposed(by: bag)
        
        // complete before
        task.completeBefore
            .map({ $0.formattedShortDateAndTime() })
            .subscribe({ [weak self] value in self?.detailsCompleteBeforeLabel.text = value })
            .disposed(by: bag)
        
        // highlight cell on change
        task.completeBefore
            .skip(1)
            .observe(on: .main)
            .subscribe({ [weak self] _ in self?.highlightView(self!.detailsCompleteBeforeLabel, animated: true)
        }).disposed(by: bag)
        
        // complete after
        task.completeAfter
            .map({ $0.formattedShortDateAndTime() })
            .subscribe({ [weak self] value in self?.detailsCompleteAfterLabel.text = value })
            .disposed(by: bag)
        
        // highlight cell on change
        task.completeAfter
            .skip(1)
            .observe(on: .main)
            .subscribe({ [weak self] _ in self?.highlightView(self!.detailsCompleteAfterLabel, animated: true)
        }).disposed(by: bag)
    }
    
    @objc private func selfAssignTask(sender: Any) {
        showActivity("Claiming...", animated: true)
        driverManager.selfAssign(task: task) { [weak self] result in
            print("self assignment result: \(result)")
            self?.hideActivityIfNeeded() {
                if case Result.failure(let error) = result {
                    self?.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
                }
            }
        }
    }
    
    @objc private func startTask(sender: Any) {
        
        guard driverManager.activeTask == nil else {
            showAlert(title: "Can't start", message: "There is already an active task.", animated: true)
            return
        }
        
        showActivity("Starting...", animated: true)
        driverManager.start(task: task) { [weak self] result in
            print("start task result: \(result)")
            self?.hideActivityIfNeeded() {
                if case Result.failure(let error) = result {
                    self?.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
                }
            }
        }
    }
    
    @objc private func completeTask(sender: Any) {
        showActivity("Completing...", animated: true)
        driverManager.complete(task: task, completionDetails: TaskCompletionDetails()) { [weak self] stats, result in
            print("complete task result: \(result)")
            self?.hideActivityIfNeeded() {
                switch result {
                case .success:
                    self?.showAlert(title: "Task Completed", message: nil, animated: true) { _ in
                        self?.navigationController?.popViewController(animated: true)
                    }
                case .failure(let error):
                    self?.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
                }
            }
        }
    }
    
    private func highlightView(_ view: UIView, animated: Bool) {
        guard animated == true else { return }
        let originalColor = view.backgroundColor
        view.superview?.backgroundColor = UIColor.yellow
        UIView.animate(withDuration: 2, animations: {
            view.superview?.backgroundColor = originalColor
        })
    }
}

import CoreLocation

extension CLLocationCoordinate2D {
    
    var formattedLatitude: String {
        let (degrees, minutes, seconds) = latitude.dms
        return String(format: "%d°%d'%d\"%@", abs(degrees), minutes, seconds, degrees >= 0 ? "N" : "S")
    }
    
    var formattedLongitude: String {
        let (degrees, minutes, seconds) = longitude.dms
        return String(format: "%d°%d'%d\"%@", abs(degrees), minutes, seconds, degrees >= 0 ? "E" : "W")
    }
    
    var formattedLocation: String {
        formattedLatitude + " " + formattedLongitude
    }
}

extension BinaryFloatingPoint {
    var dms: (degrees: Int, minutes: Int, seconds: Int) {
        var seconds = Int(self * 3600)
        let degrees = seconds / 3600
        seconds = abs(seconds % 3600)
        return (degrees, seconds / 60, seconds % 60)
    }
}

private extension Optional where Wrapped == Float {
    
    func formattedDecimal(default: String = "-") -> String {
        switch self {
        case .some(let value):
            return NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
        case .none:
            return `default`
        }
    }
    
}

private extension Optional where Wrapped == Date {
    
    func formattedShortDateAndTime(default: String = "-") -> String {
        switch self {
        case .some(let value):
            return DateFormatter.localizedString(from: value, dateStyle: .short, timeStyle: .short)
        case .none:
            return `default`
        }
    }
    
}
