//
//  StartViewController.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit

extension TopicModel {
    static var sampleData = [
            TopicModel(
                id: "Submit reimbursement report",
                name: "Don't forget about taxi receipts"),
            TopicModel(
                id: "Code review",
                name: "Check tech specs in shared folder"),
            TopicModel(
                id: "Pick up new contacts",
                name: "Optometrist closes at 6:00PM"),
            TopicModel(
                id: "Add notes to retrospective",
                name: "Collaborate with project manager"),
            TopicModel(
                id: "Interview new project manager candidate",
                name: "Review portfolio"),
        ]
}


class StartViewController: UICollectionViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, String>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, String>
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
        
        let listLayout = listLayout()
        collectionView.collectionViewLayout = listLayout
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            guard let items = try context.fetch(Topic.fetchRequest()) as? [Topic] else {
                return
            }
            for myTopic in items {
                TopicModel.sampleData.append(TopicModel.init(id: myTopic.wrappedId, name: myTopic.wrappedName))
            }
        } catch {
            print("error-Fetching data")
        }
        
        
        
        
        
        let cellRegistration = UICollectionView.CellRegistration {
            (cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: String) in
            let topic = TopicModel.sampleData[indexPath.item]
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = topic.name
            cell.contentConfiguration = contentConfiguration
        }
        
        dataSource = DataSource(collectionView: collectionView) {
                    (collectionView: UICollectionView, indexPath: IndexPath, itemIdentifier: String) in
            return collectionView.dequeueConfiguredReusableCell(
                            using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        var snapshot = Snapshot()
                snapshot.appendSections([0])
                snapshot.appendItems(TopicModel.sampleData.map { $0.name })
            dataSource.apply(snapshot)
            collectionView.dataSource = dataSource

        
        
    }
        
    private func listLayout() -> UICollectionViewCompositionalLayout {
            var listConfiguration = UICollectionLayoutListConfiguration(appearance: .grouped)
            listConfiguration.showsSeparators = false
            listConfiguration.backgroundColor = .clear
            return UICollectionViewCompositionalLayout.list(using: listConfiguration)
        }
    
    
}
