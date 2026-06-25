//
//  MainTabBarController.swift
//  SampleApp
//

import UIKit
import OnfleetDriver

final class MainTabBarController: UITabBarController {

    private let context: DriverContext

    init(context: DriverContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        let storyboard = UIStoryboard(name: "MainStoryboard", bundle: nil)

        // Tab 0: Legacy flow — instantiate from storyboard using the identifier we added
        let legacyNav = storyboard.instantiateViewController(withIdentifier: "LegacyDutyNavigationController")
        legacyNav.tabBarItem = UITabBarItem(title: "Legacy", image: UIImage(systemName: "clock"), tag: 0)

        // Tab 1: New API flow — inject dependencies from composition root
        let dutyVC = DutyViewController(
            dutyStatusManager: context.dutyStatusManager,
            tasksManager: context.tasksManager,
            driverManager: context.driverManager,
            organizationManager: context.organizationManager
        )
        let newAPINav = UINavigationController(rootViewController: dutyVC)
        newAPINav.tabBarItem = UITabBarItem(title: "New API", image: UIImage(systemName: "sparkles"), tag: 1)

        viewControllers = [legacyNav, newAPINav]
    }
}
