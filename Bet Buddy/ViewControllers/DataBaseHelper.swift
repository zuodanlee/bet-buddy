import UIKit
import CoreData

class DataBaseHelper {
    
    static let instance = DataBaseHelper()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func saveImageinCoreData(at imgData: Data){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
        do{
            let profile = try context.fetch(fetchRequest)[0]
            (profile as AnyObject).setValue(imgData,forKey: "image")
            do{
                try context.save()
            }
        }catch let error{
            print(error.localizedDescription)
        }
    }
    
    func getProfile() -> Profile?{
        var profile: Profile!
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
        do{
            profile = try context.fetch(fetchRequest)[0] as? Profile
        }catch let error{
            print(error.localizedDescription)
        }
        return profile
    }
}
