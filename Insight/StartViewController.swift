//
//  StartViewController.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit

extension TopicModel {
    static var sampleData:[TopicModel] = [
    ]
}


class StartViewController: UICollectionViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, String>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, String>
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
        TopicModel.sampleData.removeAll()
        
        let listLayout = listLayout()
        collectionView.collectionViewLayout = listLayout
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            guard let items = try context.fetch(Topic.fetchRequest()) as? [Topic] else {
                return
            }
            for myTopic in items {
                let newTopic = TopicModel(id: myTopic.wrappedId, name: myTopic.wrappedName)
                TopicModel.sampleData.append(newTopic)
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
        snapshot.appendItems(TopicModel.sampleData.map { $0.id })
            dataSource.apply(snapshot)
            collectionView.dataSource = dataSource

        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(TopicModel.sampleData[indexPath.item])
        performSegue(withIdentifier: "showViewController", sender: TopicModel.sampleData[indexPath.item])
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if (segue.identifier == "showViewController") {
          let secondView = segue.destination as! ViewController
          let object = sender as! TopicModel
           secondView.cellId = object.id
       }
    }
    
        
    private func listLayout() -> UICollectionViewCompositionalLayout {
            var listConfiguration = UICollectionLayoutListConfiguration(appearance: .grouped)
            listConfiguration.showsSeparators = false
            listConfiguration.backgroundColor = .clear
            return UICollectionViewCompositionalLayout.list(using: listConfiguration)
        }
    
    
}
