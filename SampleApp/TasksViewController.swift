//
//  TasksViewController.swift
//  SampleApp
//

import UIKit
import OnfleetDriver

final class TasksViewController: UITableViewController {

    private final class DataSource: UITableViewDiffableDataSource<Section, Onfleet.Task> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            sectionIdentifier(for: section)?.title
        }
    }

    private enum Section: Hashable {
        case activeTask
        case assignedTasks
        case unassignedTasks

        var title: String {
            switch self {
            case .activeTask:       return "Active Task"
            case .assignedTasks:    return "Assigned Tasks"
            case .unassignedTasks:  return "Unassigned Tasks"
            }
        }
    }

    private let tasksManager: any TasksManagerProtocol

    private var activeTask: Onfleet.Task?
    private var assignedTasks: [Onfleet.Task] = []
    private var unassignedTasks: [Onfleet.Task] = []

    private var observationTask: Task<Void, Never>?

    private lazy var dataSource: DataSource = {
        let ds = DataSource(
            tableView: tableView
        ) { [weak self] tableView, indexPath, task in
            let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = task.destination.address.formattedShortAddress
            config.secondaryText = task.recipients.first?.name.value ?? task.recipients.first?.name.originalValue
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        ds.defaultRowAnimation = .fade
        return ds
    }()

    // MARK: - Init

    init(tasksManager: any TasksManagerProtocol) {
        self.tasksManager = tasksManager
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tasks"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.dataSource = dataSource
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
        observationTask = Task { [weak self, tasksManager] in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await task in tasksManager.activeTask {
                        guard !Task.isCancelled else { return }
                        await MainActor.run { [weak self] in
                            self?.activeTask = task
                            self?.applySnapshot()
                        }
                    }
                }

                group.addTask { [weak self] in
                    for await tasks in tasksManager.assignedTasks {
                        guard !Task.isCancelled else { return }
                        await MainActor.run { [weak self] in
                            self?.assignedTasks = tasks
                            self?.applySnapshot()
                        }
                    }
                }

                group.addTask { [weak self] in
                    for await tasks in tasksManager.unassignedTasks {
                        guard !Task.isCancelled else { return }
                        await MainActor.run { [weak self] in
                            self?.unassignedTasks = tasks
                            self?.applySnapshot()
                        }
                    }
                }
            }
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Onfleet.Task>()
        if let activeTask {
            snapshot.appendSections([.activeTask])
            snapshot.appendItems([activeTask], toSection: .activeTask)
        }
        if !assignedTasks.isEmpty {
            snapshot.appendSections([.assignedTasks])
            snapshot.appendItems(assignedTasks, toSection: .assignedTasks)
        }
        if !unassignedTasks.isEmpty {
            snapshot.appendSections([.unassignedTasks])
            snapshot.appendItems(unassignedTasks, toSection: .unassignedTasks)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let task = dataSource.itemIdentifier(for: indexPath) else { return }
        let detail = TaskViewController(task: task, tasksManager: tasksManager)
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - Onfleet.Address helpers

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
