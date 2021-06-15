//
//  NetfoxListViewController.swift
//  
//
//  Created by Clément Nonn on 15/06/2021.
//

#if os(iOS)

import Foundation
import UIKit

extension NFXListCell {
    static let reuseIdentifier = String(describing: self)
}

open class NetfoxListViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, DataCleaner {
    // MARK: Properties

    public private(set) var searchController = UISearchController(searchResultsController: nil)

    var tableData = [NFXHTTPModel]()
    var filteredTableData = [NFXHTTPModel]()
    var selectedModel: NFXHTTPModel = NFXHTTPModel()

    // MARK: View Life Cycle

    public override func viewDidLoad()
    {
        super.viewDidLoad()

        self.tableView.register(NFXListCell.self, forCellReuseIdentifier: NFXListCell.reuseIdentifier)

        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                barButtonSystemItem: .trash,
                target: self,
                action: #selector(NetfoxListViewController.trashButtonPressed)
            ),
            UIBarButtonItem(
                image: UIImage.NFXSettings(),
                style: .plain,
                target: self,
                action: #selector(NetfoxListViewController.settingsButtonPressed)
            )
        ]

        self.searchController.searchResultsUpdater = self
        self.searchController.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.searchBarStyle = .minimal

        self.navigationItem.searchController = self.searchController
        self.definesPresentationContext = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NetfoxListViewController.reloadTableViewData),
            name: NSNotification.Name.NFXReloadData,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NetfoxListViewController.deactivateSearchController),
            name: NSNotification.Name.NFXDeactivateSearch,
            object: nil
        )
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTableViewData()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        NFX.sharedInstance().presented = false
    }

    @objc func settingsButtonPressed() {
        let style: UITableView.Style
        if #available(iOS 13.0, *) {
            style = .insetGrouped
        } else {
            style = .grouped
        }

        self.navigationController?.pushViewController(NetfoxSettingsController(style: style), animated: true)
    }

    @objc func trashButtonPressed() {
        self.clearData(sourceView: tableView, originingIn: nil) {
            self.reloadTableViewData()
        }
    }

    private func updateSearchResultsForSearchControllerWithString(_ searchString: String) {
        let predicateURL = NSPredicate(format: "requestURL contains[cd] '\(searchString)'")
        let predicateMethod = NSPredicate(format: "requestMethod contains[cd] '\(searchString)'")
        let predicateType = NSPredicate(format: "responseType contains[cd] '\(searchString)'")
        let predicates = [predicateURL, predicateMethod, predicateType]
        let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)

        self.filteredTableData = (NFXHTTPModelManager.sharedInstance.getModels() as NSArray)
            .filtered(using: searchPredicate) as! [NFXHTTPModel]
    }

    // MARK: UISearchResultsUpdating

    public func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        self.updateSearchResultsForSearchControllerWithString(text)
        reloadTableViewData()
    }

    @objc func deactivateSearchController() {
        self.searchController.isActive = false
    }

    // MARK: UITableViewDataSource

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchController.isActive {
            return self.filteredTableData.count
        } else {
            return NFXHTTPModelManager.sharedInstance.getModels().count
        }
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: NFXListCell.reuseIdentifier, for: indexPath) as! NFXListCell

        if self.searchController.isActive {
            if !self.filteredTableData.isEmpty {
                let obj = self.filteredTableData[indexPath.row]
                cell.configForObject(obj)
            }
        } else {
            if !NFXHTTPModelManager.sharedInstance.getModels().isEmpty {
                let obj = NFXHTTPModelManager.sharedInstance.getModels()[indexPath.row]
                cell.configForObject(obj)
            }
        }

        return cell
    }

    public override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    @objc func reloadTableViewData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.setNeedsDisplay()
        }
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailsController = NetfoxDetailViewController()
        let model: NFXHTTPModel
        if self.searchController.isActive {
            model = self.filteredTableData[indexPath.row]
        } else {
            model = NFXHTTPModelManager.sharedInstance.getModels()[indexPath.row]
        }
        detailsController.selectedModel = model

        self.navigationController?.pushViewController(detailsController, animated: true)
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 58
    }
}

#endif

