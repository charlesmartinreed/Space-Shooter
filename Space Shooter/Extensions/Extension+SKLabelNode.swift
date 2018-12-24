//
//  Extension+SKLabelNode.swift
//  Space Shooter
//
//  Created by Charles Martin Reed on 12/24/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

import UIKit
import GameKit

extension SKLabelNode {
    static let scoreLabel: SKLabelNode = {
        let label = SKLabelNode()
        label.text = "Score: 0"
        label.fontName = "Avenir-Black"
        label.fontSize = 40
        label.fontColor = UIColor.white
        return label
    }()
}
