//
//  DriverInfoViewController.swift
//  SampleApp
//

import UIKit
import OnfleetDriver

final class DriverInfoViewController: UITableViewController {

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case driver
        case organization
        case rawConfig
        case rawDriverAppConfig
        case rawEnabledFeatures

        var title: String {
            switch self {
            case .driver:               return "Driver"
            case .organization:         return "Organization"
            case .rawConfig:            return "config (raw)"
            case .rawDriverAppConfig:   return "driverAppConfig (raw)"
            case .rawEnabledFeatures:   return "enabledFeatures (raw)"
            }
        }
    }

    // MARK: - State

    private let driverManager: DriverManagerProtocol
    private let organizationManager: OrganizationManagerProtocol

    private var driver: Onfleet.Driver?
    private var organization: Onfleet.Organization?
    private var observationTask: Task<Void, Never>?

    // Sorted key-value pairs extracted from StructuredValue.content
    private var configRows: [(key: String, value: String)] = []
    private var driverAppConfigRows: [(key: String, value: String)] = []
    private var enabledFeaturesRows: [(key: String, value: String)] = []

    // MARK: - Init

    init(driverManager: DriverManagerProtocol, organizationManager: OrganizationManagerProtocol) {
        self.driverManager = driverManager
        self.organizationManager = organizationManager
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Driver Info"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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
        observationTask = Task { [weak self, organizationManager, driverManager] in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await driver in driverManager.driver {
                        guard !Task.isCancelled else { return }
                        await MainActor.run { [weak self] in
                            self?.driver = driver
                            self?.tableView.reloadSections(
                                IndexSet(integer: Section.driver.rawValue),
                                with: .automatic
                            )
                        }
                    }
                }

                group.addTask { [weak self] in
                    for await org in organizationManager.organization {
                        guard !Task.isCancelled else { return }
                        await MainActor.run { [weak self] in
                            self?.organization = org
                            if let org {
                                self?.configRows = org.config.sortedRows
                                self?.driverAppConfigRows = org.driverAppConfig.sortedRows
                                self?.enabledFeaturesRows = org.enabledFeatures.sortedRows
                            } else {
                                self?.configRows = []
                                self?.driverAppConfigRows = []
                                self?.enabledFeaturesRows = []
                            }
                            self?.tableView.reloadSections(
                                IndexSet([
                                    Section.organization.rawValue,
                                    Section.rawConfig.rawValue,
                                    Section.rawDriverAppConfig.rawValue,
                                    Section.rawEnabledFeatures.rawValue
                                ]),
                                with: .automatic
                            )
                        }
                    }
                }
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
        case .driver:
            return driver != nil ? 4 : 1  // name, phone, onDuty, active tasks count
        case .organization:
            return organization != nil ? 4 : 1  // name, id, country, email
        case .rawConfig:
            return configRows.isEmpty ? 1 : configRows.count
        case .rawDriverAppConfig:
            return driverAppConfigRows.isEmpty ? 1 : driverAppConfigRows.count
        case .rawEnabledFeatures:
            return enabledFeaturesRows.isEmpty ? 1 : enabledFeaturesRows.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        var config = cell.defaultContentConfiguration()

        switch Section(rawValue: indexPath.section)! {

        case .driver:
            guard let driver else {
                config.text = "Loading..."
                break
            }
            switch indexPath.row {
            case 0:
                config.text = "Name"
                config.secondaryText = driver.name
            case 1:
                config.text = "Phone"
                config.secondaryText = driver.phone
            case 2:
                config.text = "On Duty"
                config.secondaryText = String(driver.onDuty)
            case 3:
                config.text = "Assigned Tasks"
                config.secondaryText = String(driver.tasks.count)
            default: break
            }

        case .organization:
            guard let org = organization else {
                config.text = "Loading..."
                break
            }
            switch indexPath.row {
            case 0:
                config.text = "Name"
                config.secondaryText = org.name
            case 1:
                config.text = "ID"
                config.secondaryText = org.id
            case 2:
                config.text = "Country"
                config.secondaryText = org.country
            case 3:
                config.text = "Email"
                config.secondaryText = org.email
            default: break
            }

        case .rawConfig:
            configure(&config, fromRows: configRows, at: indexPath.row)

        case .rawDriverAppConfig:
            configure(&config, fromRows: driverAppConfigRows, at: indexPath.row)

        case .rawEnabledFeatures:
            configure(&config, fromRows: enabledFeaturesRows, at: indexPath.row)
        }

        cell.contentConfiguration = config
        return cell
    }

    // MARK: - Helpers

    private func configure(
        _ config: inout UIListContentConfiguration,
        fromRows rows: [(key: String, value: String)],
        at row: Int
    ) {
        if rows.isEmpty {
            config.text = "(empty)"
        } else {
            config.text = rows[row].key
            config.secondaryText = rows[row].value
        }
    }
}

// MARK: - StructuredValue raw display

private extension Onfleet.StructuredValue {

    var sortedRows: [(key: String, value: String)] {
        content.sorted { $0.key < $1.key }.map { (key: $0.key, value: $0.value.displayText) }
    }
}

private extension Onfleet.StructuredValue.Element {

    var displayText: String {
        switch self {
        case .int(let v):       return "\(v)"
        case .double(let v):    return "\(v)"
        case .string(let v):    return v
        case .bool(let v):      return "\(v)"
        case .null:             return "null"
        case .object(let sv):   return "{\(sv.content.count) keys}"
        case .array(let arr):   return arr.displayText
        }
    }
}

private extension Onfleet.StructuredValue.Element.ArrayElement {

    var displayText: String {
        switch self {
        case .int(let v):       return v.map(String.init).joined(separator: ", ")
        case .double(let v):    return v.map { String($0) }.joined(separator: ", ")
        case .string(let v):    return v.joined(separator: ", ")
        case .bool(let v):      return v.map(String.init).joined(separator: ", ")
        case .object(let v):    return "[\(v.count) objects]"
        }
    }
}
