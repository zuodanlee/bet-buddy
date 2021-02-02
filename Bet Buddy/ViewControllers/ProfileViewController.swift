import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate ,UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var profileView: UIView!
    var imagePicker = UIImagePickerController()
    var selectedVew: UIView!
 
    func styling() {
        profileView.backgroundColor = Colours.primaryRed
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styling()
        
        let profilepic = DataBaseHelper().getProfile()?.image
        if profilepic != nil {
            imageView.image = UIImage(data: profilepic!)
        }
        
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = false
        
        [imageView].forEach {
            $0?.isUserInteractionEnabled = true
            $0?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(chooseImage)))
        }
        imageView.layer.borderWidth = 1
        imageView.layer.masksToBounds = false
        imageView.layer.borderColor = UIColor.red.cgColor
        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.clipsToBounds = true
    }
    
    @objc func chooseImage(_ gesture: UITapGestureRecognizer) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            selectedVew = gesture.view
            present(imagePicker, animated: true)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        (selectedVew as? UIImageView)?.image = info[.originalImage] as? UIImage
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    
    @IBAction func saveBtn(_ sender: UIButton) {
        let _ = self.imageView.image?.jpegData(compressionQuality: 0.75)
        if let png = self.imageView.image?.pngData() {
            DataBaseHelper.instance.saveImageinCoreData(at: png)
            let profile = DataBaseHelper.instance.getProfile()!
            self.imageView.image = UIImage(data: profile.image!)
        }
        
    }
}
