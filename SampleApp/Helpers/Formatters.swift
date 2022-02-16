//
//  Formatters.swift
//  SampleApp
//
//  Created by Peter Stajger on 16/11/2021.
//  Copyright © 2021 Onfleet Inc. All rights reserved.
//

import Foundation

extension String.StringInterpolation {
    mutating func appendInterpolation(seconds: Int, allowedUnits: NSCalendar.Unit) {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = allowedUnits
        if let string = formatter.string(from: DateComponents(second: seconds)) {
            appendLiteral(string)
        }
    }
}
