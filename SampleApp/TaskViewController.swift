//
//  TaskViewController.swift
//  SampleApp
//

import UIKit
import OnfleetDriver

final class TaskViewController: UITableViewController, ActivityShowing {

    var activityAlert: UIAlertController?

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case state
        case recipient
        case destination
        case scheduling
        case completionRequirements
        case customFields

        var title: String {
            switch self {
            case .state:                    return "State"
            case .recipient:                return "Recipient"
            case .destination:              return "Destination"
            case .scheduling:               return "Scheduling"
            case .completionRequirements:   return "Completion Requirements"
            case .customFields:             return "Custom Fields"
            }
        }
    }

    // MARK: - State

    private var task: Onfleet.Task
    private var completionRequirements: Onfleet.Task.CompletionRequirements?
    private var observationTask: Task<Void, Never>?

    private let tasksManager: any TasksManagerProtocol

    // MARK: - Init

    init(task: Onfleet.Task, tasksManager: any TasksManagerProtocol) {
        self.task = task
        self.tasksManager = tasksManager
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "#\(task.shortId)"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        updateActionButton()
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

    // MARK: - Observation

    private func startObserving() {
        observationTask = Task { [weak self, tasksManager, task] in
            await withTaskGroup(of: Void.self) { group in

                // observe completion requirements stream
                group.addTask { [weak self] in
                    for await reqs in tasksManager.completionRequirements(for: task) {
                        guard !Task.isCancelled else { return }
                        await MainActor.run { [weak self] in
                            guard let self else { return }
                            self.completionRequirements = reqs
                            self.tableView.reloadSections(
                                IndexSet(integer: Section.completionRequirements.rawValue),
                                with: .automatic
                            )
                        }
                    }
                }

                // observe assigned tasks for self-assign updates
                group.addTask { [weak self] in
                    for await tasks in tasksManager.assignedTasks {
                        guard !Task.isCancelled else { return }
                        await MainActor.run { [weak self] in
                            guard let self else { return }
                            if let updated = tasks.first(where: { $0.id == self.task.id }), updated != self.task {
                                self.task = updated
                                self.tableView.reloadData()
                                self.updateActionButton()
                            }
                        }
                    }
                }

                // observe active task for start updates
                group.addTask { [weak self] in
                    for await active in tasksManager.activeTask {
                        guard !Task.isCancelled else { return }
                        await MainActor.run { [weak self] in
                            guard let self else { return }
                            if let active, active.id == self.task.id, active != self.task {
                                self.task = active
                                self.tableView.reloadData()
                                self.updateActionButton()
                            }
                        }
                    }
                }

                // observe available tasks for unassign/reassign updates
                group.addTask { [weak self] in
                    for await tasks in tasksManager.availableTasks {
                        guard !Task.isCancelled else { return }
                        await MainActor.run { [weak self] in
                            guard let self else { return }
                            if let updated = tasks.first(where: { $0.id == self.task.id }), updated != self.task {
                                self.task = updated
                                self.tableView.reloadData()
                                self.updateActionButton()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action button

    private func updateActionButton() {
        if task.isActive {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Complete",
                style: .done,
                target: self,
                action: #selector(completeTask)
            )
        } else if task.isSelfAssignable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Claim",
                style: .done,
                target: self,
                action: #selector(claimTask)
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Start",
                style: .done,
                target: self,
                action: #selector(startTask)
            )
        }
    }

    // MARK: - Task actions

    @objc private func startTask() {
        showActivity("Starting...", animated: true)
        Task { @MainActor [weak self, tasksManager, task] in
            guard let self else { return }
            do {
                try await tasksManager.start(task: task)
                self.hideActivityIfNeeded()
            } catch {
                self.hideActivityIfNeeded()
                self.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
            }
        }
    }

    @objc private func claimTask() {
        showActivity("Claiming...", animated: true)
        Task { @MainActor [weak self, tasksManager, task] in
            guard let self else { return }
            do {
                try await tasksManager.selfAssign(task: task)
                self.hideActivityIfNeeded()
            } catch {
                self.hideActivityIfNeeded()
                self.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
            }
        }
    }

    @objc private func completeTask() {
        showActivity("Completing...", animated: true)
        Task { @MainActor [weak self, tasksManager, task] in
            guard let self else { return }
            do {
                _ = try await tasksManager.complete(task: task, completionDetails: TaskCompletionDetails())
                self.hideActivityIfNeeded()
                self.showAlert(title: "Task Completed", message: nil, animated: true) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
            } catch {
                self.hideActivityIfNeeded()
                self.showAlert(title: "Failed", message: error.localizedDescription, animated: true)
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .state:
            return 3 // isActive, isSelfAssignable, isSelfAssigned
        case .recipient:
            let count = task.recipients.count
            // 2 rows per recipient (name + notes) plus 1 for phone
            return count == 0 ? 1 : count * 3
        case .destination:
            return 3 // address, coordinates, notes
        case .scheduling:
            return 3 // type, completeAfter, completeBefore
        case .completionRequirements:
            return 5 // photos, signature, barcodes, ageVerification, notes
        case .customFields:
            let count = task.customFields?.count ?? 0
            return count == 0 ? 1 : count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        var config = cell.defaultContentConfiguration()

        switch Section(rawValue: indexPath.section)! {

        case .state:
            switch indexPath.row {
            case 0:
                config.text = "Active"
                config.secondaryText = String(task.isActive)
            case 1:
                config.text = "Self Assignable"
                config.secondaryText = String(task.isSelfAssignable)
            case 2:
                config.text = "Self Assigned"
                config.secondaryText = String(task.isSelfAssigned)
            default: break
            }

        case .recipient:
            guard !task.recipients.isEmpty else {
                config.text = "No recipient"
                break
            }
            let recipientIndex = indexPath.row / 3
            let fieldIndex = indexPath.row % 3
            let recipient = task.recipients[recipientIndex]
            switch fieldIndex {
            case 0:
                // OverrideableProperty.value demonstration
                let nameValue = recipient.name.value ?? "—"
                let originalName = recipient.name.originalValue ?? "—"
                let overridden = recipient.name.overriddenValue != nil
                config.text = "Name (.value)"
                config.secondaryText = overridden
                    ? "\(nameValue) (original: \(originalName), overridden)"
                    : nameValue
            case 1:
                config.text = "Phone"
                config.secondaryText = recipient.phone ?? "—"
            case 2:
                let notesValue = recipient.notes.value ?? "—"
                let originalNotes = recipient.notes.originalValue ?? "—"
                let overridden = recipient.notes.overriddenValue != nil
                config.text = "Notes (.value)"
                config.secondaryText = overridden
                    ? "\(notesValue) (original: \(originalNotes), overridden)"
                    : notesValue
            default: break
            }

        case .destination:
            let dest = task.destination
            switch indexPath.row {
            case 0:
                config.text = "Address"
                config.secondaryText = dest.address.formattedShortAddress
            case 1:
                config.text = "Coordinates"
                config.secondaryText = dest.location.formattedLocation
            case 2:
                config.text = "Notes"
                config.secondaryText = dest.notes ?? "—"
            default: break
            }

        case .scheduling:
            switch indexPath.row {
            case 0:
                config.text = "Type"
                config.secondaryText = task.type.isPickUp ? "Pickup" : "Dropoff"
            case 1:
                config.text = "Complete After"
                config.secondaryText = task.completeAfter.formattedShortDateAndTime()
            case 2:
                config.text = "Complete Before"
                config.secondaryText = task.completeBefore.formattedShortDateAndTime()
            default: break
            }

        case .completionRequirements:
            let reqs = completionRequirements
            switch indexPath.row {
            case 0:
                config.text = "Photos"
                config.secondaryText = reqs?.photos.displayName ?? "—"
            case 1:
                config.text = "Signature"
                config.secondaryText = reqs?.signature.displayName ?? "—"
            case 2:
                config.text = "Barcodes"
                config.secondaryText = reqs?.barcodes.displayName ?? "—"
            case 3:
                config.text = "Age Verification"
                config.secondaryText = reqs?.ageVerification.displayName ?? "—"
            case 4:
                config.text = "Notes"
                config.secondaryText = reqs?.notes.displayName ?? "—"
            default: break
            }

        case .customFields:
            let fields = task.customFields ?? []
            if fields.isEmpty {
                config.text = "No custom fields"
            } else {
                let field = fields[indexPath.row]
                config.text = field.name
                config.secondaryText = field.value.displayText
            }
        }

        cell.contentConfiguration = config
        return cell
    }
}

// MARK: - Helpers

private extension Onfleet.LocationCoordinates {

    var formattedLocation: String {
        formattedLatitude + " " + formattedLongitude
    }

    var formattedLatitude: String {
        let (degrees, minutes, seconds) = latitude.dms
        return String(format: "%d°%d'%d\"%@", abs(degrees), minutes, seconds, degrees >= 0 ? "N" : "S")
    }

    var formattedLongitude: String {
        let (degrees, minutes, seconds) = longitude.dms
        return String(format: "%d°%d'%d\"%@", abs(degrees), minutes, seconds, degrees >= 0 ? "E" : "W")
    }
}

private extension Onfleet.Address {

    var formattedShortAddress: String {
        if let name { return name }
        var parts = [String]()
        if let number { parts.append(number) }
        if let street { parts.append(street) }
        if !parts.isEmpty { return parts.joined(separator: " ") }
        return city
    }
}

private extension Optional where Wrapped == Date {

    func formattedShortDateAndTime(default defaultValue: String = "—") -> String {
        switch self {
        case .some(let value):
            return DateFormatter.localizedString(from: value, dateStyle: .short, timeStyle: .short)
        case .none:
            return defaultValue
        }
    }
}

private extension Onfleet.Task.CompletionRequirement {

    var displayName: String {
        switch self {
        case .unknown:  return "Unknown"
        case .required: return "Required"
        case .optional: return "Optional"
        case .disabled: return "Disabled"
        }
    }
}

private extension Onfleet.CustomField.Value {

    var displayText: String {
        switch self {
        case .boolean(let v):           return String(v)
        case .integer(let v):           return String(v)
        case .decimal(let v):           return String(v)
        case .date(let v):              return DateFormatter.localizedString(from: v, dateStyle: .short, timeStyle: .none)
        case .url(let v):               return v.absoluteString
        case .singleLineText(let v):    return v
        case .multiLineText(let v):     return v
        case .checklist(let items):     return items.filter(\.isSelected).map(\.name).joined(separator: ", ")
        }
    }
}
