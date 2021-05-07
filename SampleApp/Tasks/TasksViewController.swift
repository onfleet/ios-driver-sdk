//
//  TasksViewController.swift
//  SampleApp
//
//  Created by Peter Stajger on 14/01/2021.
//

import UIKit
import RxSwift
import OnfleetDriver

final class TasksViewController : UITableViewController, ActivityShowing {
    
    enum Section : Int, CaseIterable {
        case activeTask
        case assignedTasks
        case selfAssignableTasks
    }
    
    var activityAlert: UIAlertController?
    
    private let driverContext = DriverContext.shared
    private let driverManager = DriverContext.shared.driverManager
    private var bag: DisposeBag?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refetchData(sender:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeData()
    }
    
    private func observeData() {
        let bag = DisposeBag()
        observeDataFetchingState(disposeBy: bag)
        observeDataState(disposeBy: bag)
        observeDriverChanges(disposeBy: bag)
        self.bag = bag
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingData()
    }
    
    private func stopObservingData() {
        self.bag = nil
    }
    
    private func observeDataFetchingState(disposeBy bag: DisposeBag) {
        driverContext.fetchingState.subscribe(onChange: { [weak self] (fetchingState) in
            print("fetching state: \(fetchingState)")
            switch fetchingState {
            case .fetching:
                self?.refreshControl?.beginRefreshing()
            case .idle:
                self?.refreshControl?.endRefreshing()
                self?.tableView.reloadData()
            }
        }).disposed(by: bag)
    }
    
    private func observeDataState(disposeBy bag: DisposeBag) {
        driverContext.dataState.subscribe(onChange: { [weak self] (dataState) in
            print("data state: \(dataState)")
            if case DataState.error = dataState {
                self?.showAlertPrompt(title: "Data Failed", message: "Something went wrong with data fetch", action: UIAlertAction(title: "Refetch", style: .default, handler: { (_) in
                    self?.refetchData()
                }), animated: true)
            }
        }).disposed(by: bag)
    }
    
    private func observeDriverChanges(disposeBy bag: DisposeBag) {
        
        func observeDriver() {
            driverManager.driver?.subscribeOnChangeWithChildren({ [weak self] in
                print("driver object graph changed, reloading UI")
                self?.tableView.reloadData()
            }).disposed(by: bag)
        }
        
        if driverManager.driver != nil {
            observeDriver()
        }
        else {
            driverManager.driverAvailable$.subscribe(onChange: { _ in
                observeDriver()
            }).disposed(by: bag)
        }
    }
    
    @objc private func refetchData(sender: UIRefreshControl) {
        refetchData()
    }
    
    private func refetchData() {
        driverContext.refetchData(completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .activeTask: return driverManager.driver?.activeTask != nil ? 1 : 0
        case .assignedTasks: return driverManager.driver?.tasks.count ?? 0
        case .selfAssignableTasks: return driverManager.selfAssignableTasks.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCellId", for: indexPath) as! TaskTableViewCell
        cell.update(with: task(at: indexPath))
        return cell
    }
    
    private func task(at indexPath: IndexPath) -> Task? {
        switch Section(rawValue: indexPath.section)! {
        case .activeTask:
            return driverManager.driver?.activeTask
        case .assignedTasks:
            return driverManager.driver?.tasks[indexPath.row]
        case .selfAssignableTasks:
            return driverManager.selfAssignableTasks[indexPath.row]
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "TaskDetailSegueId", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TaskDetailSegueId", let taskViewController = segue.destination as? TaskViewController {
            if let selectedPath = tableView.indexPathForSelectedRow, let task = self.task(at: selectedPath) {
                taskViewController.task = task
                taskViewController.driverManager = driverManager
            }
        }
        super.prepare(for: segue, sender: sender)
    }
}

extension Address {
    
    var formattedShortAddress: String {
        return (name ?? formattedLine1) ?? city
    }
    
    var formattedLine1: String? {
        var components = [String]()
        if let number = number {
            components.append(number)
        }
        if let street = street {
            components.append(street)
        }
        return components.isEmpty ? nil : components.joined(separator: " ")
    }
}
