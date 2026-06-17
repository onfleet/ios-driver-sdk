//
//  DutyViewController.swift
//  SampleApp
//

import UIKit
import OnfleetDriver

final class DutyViewController: UIViewController, ActivityShowing {

    var activityAlert: UIAlertController?

    private let dutyStatusManager: any DutyStatusManagerProtocol
    private let tasksManager: any TasksManagerProtocol
    private let driverManager: DriverManagerProtocol
    private let organizationManager: OrganizationManagerProtocol

    private let dutySwitch = UISwitch()
    private var observationTask: Task<Void, Never>?

    private let onDutyChild: TasksViewController
    private let offDutyChild = OffDutyViewController()

    // MARK: - Init

    init(
        dutyStatusManager: any DutyStatusManagerProtocol,
        tasksManager: any TasksManagerProtocol,
        driverManager: DriverManagerProtocol,
        organizationManager: OrganizationManagerProtocol
    ) {
        self.dutyStatusManager = dutyStatusManager
        self.tasksManager = tasksManager
        self.driverManager = driverManager
        self.organizationManager = organizationManager
        self.onDutyChild = TasksViewController(tasksManager: tasksManager)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "New API"
        setupNavigationBar()
        setupDutySwitch()
        setupChildViewControllers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startObserving()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        observationTask?.cancel()
        observationTask = nil
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Driver Info",
            style: .plain,
            target: self,
            action: #selector(showDriverInfo)
        )
    }

    private func setupDutySwitch() {
        dutySwitch.addTarget(self, action: #selector(dutySwitchChanged), for: .valueChanged)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dutySwitch)
    }

    private func setupChildViewControllers() {
        addChild(onDutyChild)
        view.addSubview(onDutyChild.view)
        onDutyChild.view.frame = view.bounds
        onDutyChild.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        onDutyChild.didMove(toParent: self)

        addChild(offDutyChild)
        view.addSubview(offDutyChild.view)
        offDutyChild.view.frame = view.bounds
        offDutyChild.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        offDutyChild.didMove(toParent: self)

        // start with off-duty visible until we get real state
        showOffDuty()
    }

    // MARK: - Observation

    private func startObserving() {
        observationTask = Task { [weak self, dutyStatusManager] in
            for await state in dutyStatusManager.dutyStatusState {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.apply(dutyStatusState: state)
                }
            }
        }
    }

    private func apply(dutyStatusState state: Onfleet.DutyStatusState) {
        let isOnDuty = state.status?.isOnDuty ?? false
        dutySwitch.setOn(isOnDuty, animated: true)
        if isOnDuty {
            showOnDuty()
        } else {
            showOffDuty()
        }
    }

    private func showOnDuty() {
        view.bringSubviewToFront(onDutyChild.view)
        onDutyChild.view.isHidden = false
        offDutyChild.view.isHidden = true
    }

    private func showOffDuty() {
        view.bringSubviewToFront(offDutyChild.view)
        offDutyChild.view.isHidden = false
        onDutyChild.view.isHidden = true
    }

    // MARK: - Actions

    @objc private func dutySwitchChanged() {
        let goOnDuty = dutySwitch.isOn
        showActivity("Going \(goOnDuty ? "on" : "off") duty...", animated: true)
        Task { @MainActor [weak self, dutyStatusManager] in
            guard let self else { return }
            do {
                try await dutyStatusManager.setDutyStatus(goOnDuty: goOnDuty)
                self.hideActivityIfNeeded()
            } catch {
                self.hideActivityIfNeeded()
                self.dutySwitch.setOn(!goOnDuty, animated: true)
                self.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
            }
        }
    }

    @objc private func showDriverInfo() {
        let vc = DriverInfoViewController(
            driverManager: driverManager,
            organizationManager: organizationManager
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}
