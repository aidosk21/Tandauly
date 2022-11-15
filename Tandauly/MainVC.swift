//
//  MainVC.swift
//  Tandauly
//
//  Created by Aidos on 19.10.2022.
//

import UIKit
import RealmSwift

class MainVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    private var places: Results<Place>!
    private var filteredPlaces: Results<Place>!
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var isFiltering: Bool {
        searchController.isActive && !searchBarIsEmty
    }
    
    private var searchBarIsEmty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        places = realm.objects(Place.self)
        setupSearchController()
    }
    
    func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        searchController.searchBar.setValue("Отменить", forKey: "cancelButtonText")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show" {
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
            let newPlaceVC = segue.destination as! NewPlaceVC
            newPlaceVC.currentPlace = place
        }
    }
    
    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
        guard let newPlaceVC = segue.source as? NewPlaceVC else { return }
        newPlaceVC.savePlace()

        tableView.reloadData()
        
    }
    
    

// MARK: - Table view data source


     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         if isFiltering {
             return filteredPlaces.count
         }
         return places.count
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! PlaceCell
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        cell.setup(place: place)
        return cell
    }
    
    
     func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let place = places[indexPath.row]
        if editingStyle == .delete {
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
     func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
    {
         return "Удалить"
    }
    
    
   
    
  
  
}

// MARK: - Main View Controller Extension
extension MainVC: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContent(searchController.searchBar.text!)
    }
    
    private func filterContent(_ searchText: String) {
        
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText)
        
        tableView.reloadData()
        
    }
    
}
