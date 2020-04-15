//
//  Constants.swift
//  Connect
//
//  Created by Nikhil Pandeti on 4/15/20.
//  Copyright © 2020 Nikhil Pandeti. All rights reserved.
//

import Foundation
import Firebase

struct Constants {
    static let allRelationships : [(String, UIColor)] = [("Friend",#colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)), ("Brother",#colorLiteral(red: 0.09019608051, green: 0, blue: 0.3019607961, alpha: 1)), ("Sister",#colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1)), ("Lab Partner",#colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1)), ("Cousin",#colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)), ("Sibling",#colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)), ("Previous Roommate",#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)), ("Acquaintance",#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))]
    static func getRelationColor(_ relationText: String) -> UIColor? {
        return Constants.allRelationships.first(where: { (arg0 : (String, UIColor)) -> Bool in
            let (relation, _) = arg0
        return relationText.lowercased() == relation.lowercased()
        })?.1
    }
}
