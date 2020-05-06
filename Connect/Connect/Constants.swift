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
    static let allRelationships : [(String, UIColor)] = [("Friend",#colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)), ("Sibling",#colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1)), ("Lab Partner",#colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1)), ("Cousin",#colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)), ("Previous Roommate",#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)), ("Acquaintance",#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)), ("Parent", #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)), ("Spouse", #colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1)), ("Relative", #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1)), ("Significant Other", #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)), ("Fiance/Fiancee", #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)), ("Sports Teammate", #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)), ("Classmate", #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)), ("Fraternity Brother", #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)), ("Sorority Sister", #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)), ("Co-Worker", #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)), ("Business Partner", #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))]
    static func getRelationColor(_ relationText: String) -> UIColor? {
        return Constants.allRelationships.first(where: { (arg0 : (String, UIColor)) -> Bool in
            let (relation, _) = arg0
        return relationText.lowercased() == relation.lowercased()
        })?.1
    }
}
