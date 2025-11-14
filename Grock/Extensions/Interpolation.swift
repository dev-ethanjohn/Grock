//
//  Interpolation.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/14/25.
//

import SwiftUI

extension CGFloat {
    func interpolate(inputRange: [CGFloat], outputRange: [CGFloat]) -> CGFloat {
        /// If value less than it's initial input range
        let x = self
        let length = inputRange.count - 1
        if x <= inputRange[0] { return outputRange[0] }
        
        for index in 1...length {
            let x1 = inputRange[index - 1]
            let x2 = inputRange[index]
            
            let y1 = outputRange[index - 1]
            let y2 = outputRange[index]
            
            /// linear tnterplation formul: y1 + ((y2-y1) / (x2-x1)) * (x-x1)
            if x <= inputRange[index] {
                let y = y1 + ((y2-y1) / (x2-x1)) * (x-x1)
                return y
            }
        }
        
        /// If value eceeds it's maximum input range
        return outputRange[length]
    }
}
