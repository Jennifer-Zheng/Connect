//
//  CustomTabBar.swift
//  Connect
//
//  Created by Evan Weiss on 4/15/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import UIKit

class CustomTabBar: UITabBar {
    // Allows us to specify tab bar heights in the storyboard editor
    @IBInspectable var height: CGFloat = 0.0
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        if height > 0.0 {
            sizeThatFits.height = height
        }
        return sizeThatFits
    }

}
