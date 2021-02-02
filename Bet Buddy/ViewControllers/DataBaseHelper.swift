import UIKit
import CoreData

class DataBaseHelper {
    
    static let instance = DataBaseHelper()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func saveImageinCoreData(at imgData: Data){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
        let profile: Profile?
        do{
            let fetchResult = try context.fetch(fetchRequest)
            if fetchResult.count > 0 {
                profile = fetchResult[0] as? Profile
                (profile as AnyObject).setValue(imgData,forKey: "image")
                do{
                    try context.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
            else {
                addNewProfile(at: imgData)
            }
        }catch let error{
            print(error.localizedDescription)
        }
    }
    
    func addNewProfile(at imgData: Data) {
        let entity = NSEntityDescription.entity(forEntityName: "Profile", in: context)!
        
        let profile = NSManagedObject(entity: entity, insertInto: context)
        profile.setValue(imgData, forKey: "image")
        
        do {
            try context.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func getProfile() -> Profile?{
        var profile: Profile!
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
        do{
            let fetchResult = try context.fetch(fetchRequest)
            if fetchResult.count > 0 {
                profile = fetchResult[0] as? Profile
            }
            else {
                profile = nil
            }
        }catch let error{
            print(error.localizedDescription)
        }
        return profile
    }
}
