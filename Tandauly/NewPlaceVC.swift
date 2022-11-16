//
//  NewPlaceTableVC.swift
//  Tandauly
//
//  Created by Aidos on 03.11.2022.
//

import UIKit
import RealmSwift
import Cosmos

class NewPlaceVC: UITableViewController {
    
    var currentPlace: Place?
    private var imageChanged = false
    var currentRating = 0.0
   
    
    
    @IBOutlet weak var mapImage: UIButton!
    @IBOutlet weak var cosmosView: CosmosView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var placeNameTF: UITextField!
    @IBOutlet weak var placeTypeTF: UITextField!
    @IBOutlet weak var placeLocationTF: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cosmosView.didTouchCosmos = { rating in
            self.currentRating = rating
        }

        saveButton.isEnabled = false
        setupEditView()
        placeNameTF.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
    }
    
    
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            
            let cameraIcon = UIImage(systemName: "camera")
            let photoLibraryIcon = UIImage(systemName: "photo")
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let camera = UIAlertAction(title: "Камера", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            let photo = UIAlertAction(title: "Фотопленка", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            
            
            
            camera.setValue(cameraIcon, forKey: "image")
            photo.setValue(photoLibraryIcon, forKey: "image")
            let cancel = UIAlertAction(title: "Отменить", style: .cancel)
            
            alert.addAction(camera)
            alert.addAction(photo)
            alert.addAction(cancel)
            
            present(alert, animated: true)
        } else {
            view.endEditing(true)
        }
    }
    
    
    
    func savePlace() {
        
        let newImg = imageChanged ? placeImage.image : UIImage(named: "map")
        let imageData = newImg?.pngData()
        
        let newPlace = Place(name: placeNameTF.text!, location: placeLocationTF.text, type: placeTypeTF.text, imageData: imageData, rating: currentRating)
        
        if currentPlace != nil {
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else {
            StorageManager.saveObject(newPlace)
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let identifier = segue.identifier,
            let mapVC = segue.destination as? MapVC
            else { return }
        mapVC.segueIdentifier = identifier
        mapVC.mapVCDelegate = self
        
        if identifier == "showPlace" {
            mapVC.place.name = placeNameTF.text!
            mapVC.place.type = placeTypeTF.text!
            mapVC.place.imageData = placeImage.image?.pngData()
            mapVC.place.location = placeLocationTF.text
        }
    }
    
    private func setupEditView() {
        if currentPlace != nil {
            guard let data = currentPlace?.imageData else { return }
            let image = UIImage(data: data)
            imageChanged = true
            placeImage.image = image
            placeImage.contentMode = .scaleAspectFill
            placeNameTF.text = currentPlace?.name
            placeTypeTF.text = currentPlace?.type
            placeLocationTF.text = currentPlace?.location
            cosmosView.rating = currentPlace?.rating ?? 0.0
            navigationItem.leftBarButtonItem = nil
            saveButton.isEnabled = true
            title = ""
        }
    }
    
    
    
}
    
    // MARK:  Text Field Delegate
    extension NewPlaceVC: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
        
        @objc private func textFieldChanged() {
            if placeNameTF.text?.isEmpty == false {
                saveButton.isEnabled = true
            } else {
                saveButton.isEnabled = false
            }
        }
    }
    
    
    // MARK:  Work with image
    extension NewPlaceVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        func chooseImagePicker(source: UIImagePickerController.SourceType) {
            if UIImagePickerController.isSourceTypeAvailable(source) {
                let image = UIImagePickerController()
                image.delegate = self
                image.allowsEditing = true
                image.sourceType = source
                present(image, animated: true)
            }
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            placeImage.image = info[.editedImage] as? UIImage
            placeImage.contentMode = .scaleAspectFill
            placeImage.clipsToBounds = true
            
            imageChanged = true
            dismiss(animated: true)
        }
        
    }


extension UINavigationItem{
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        let backItem = UIBarButtonItem()
        backItem.title = "Назад"
        self.backBarButtonItem = backItem
        
    }
}

extension NewPlaceVC: MapVCDelegate {
    func getAddress(address: String?) {
        placeLocationTF.text = address
    }
    
    
}
    
    
    

