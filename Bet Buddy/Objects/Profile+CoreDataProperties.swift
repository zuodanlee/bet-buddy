//
//  Profile+CoreDataProperties.swift
//  
//
//  Created by Isaiah Low  on 2/2/21.
//
//

import Foundation
import CoreData


extension Profile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }

    @NSManaged public var img: Data?

}
