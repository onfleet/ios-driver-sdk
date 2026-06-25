//
//  LegacyTaskTableViewCell.swift
//  SampleApp
//
//  Created by Peter Stajger on 29/04/2021.
//

import UIKit
import OnfleetDriver

class CircleView : UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 7
        layer.masksToBounds = true
    }
}

class LegacyTaskTableViewCell : UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
}

extension LegacyTaskTableViewCell {
    func update(with task: Legacy.Task?) {
        if let task = task {
            self.titleLabel.text = task.getDestination().address.formattedShortAddress
            self.subtitleLabel.text = task.getNameForPreferredRecipient() ?? "No recipient"
            self.circleView.backgroundColor = colorForTaskState(of: task)
        }
    }
    
    private func colorForTaskState(of task: Legacy.Task) -> UIColor {
        if task.getIsFulfilled() {
            return .systemGreen
        } else if task.getIsActive() {
            return .systemBlue
        } else if task.getIsSelfAssignable() {
            return .systemOrange
        } else {
            return .systemPurple
        }
    }
}
