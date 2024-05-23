//
//  StartViewController.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit

extension TopicModel {
    //Array with all Topics. It gets fetched of Core Data
    static var topicData:[TopicModel] = [
        TopicModel(id: "AddID", name: "Add Topic")
    ]
}


class StartViewController: UICollectionViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, String>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, String>
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
            super.viewDidLoad()
        
        
        TopicModel.topicData.removeAll {
            $0.id != "AddID"
        }
        
        //Create List of Topic Names
        let listLayout = listLayout()
        collectionView.collectionViewLayout = listLayout
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            //Try to get all Topics in Core Data
            guard let items = try context.fetch(Topic.fetchRequest()) as? [Topic] else {
                return
            }
            for myTopic in items {
                //Add all Topics to the Array
                let newTopic = TopicModel(id: myTopic.wrappedId, name: myTopic.wrappedName)
                TopicModel.topicData.append(newTopic)
            }
        } catch {
            print("error-Fetching data")
        }
        
        
        
        //Configure Cells in List with Topic Names
        let cellRegistration = UICollectionView.CellRegistration {
            (cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: String) in
            let topic = TopicModel.topicData[indexPath.item]
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = topic.name
            cell.contentConfiguration = contentConfiguration
        }
        
        dataSource = DataSource(collectionView: collectionView) {
                    (collectionView: UICollectionView, indexPath: IndexPath, itemIdentifier: String) in
            return collectionView.dequeueConfiguredReusableCell(
                            using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        //Connect topicData Array to the UI List
        var snapshot = Snapshot()
                snapshot.appendSections([0])
        snapshot.appendItems(TopicModel.topicData.map { $0.id })
            dataSource.apply(snapshot)
            collectionView.dataSource = dataSource
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        print(TopicModel.topicData[indexPath.item])
        
        //Let the User add new Topic. TODO: Move this functionality to a button on the bottom right
        if(TopicModel.topicData[indexPath.item].id == "AddID") {
            let id = UUID().uuidString
            let name = ""
            let newData = Topic(context: context)
            newData.id = id
            newData.name = name
            DispatchQueue.main.async {
                do {
                    try context.save()
                    self.performSegue(withIdentifier: "showOverviewController", sender: TopicModel.init(id: id, name: name))
                    print("JO")
                } catch {
                    print("error-saving data")
                }
            }
            
        } else {
            performSegue(withIdentifier: "showOverviewController", sender: TopicModel.topicData[indexPath.item])
        }
        
        
        
    }
    
    //Transfer ID of tapped Cell
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if (segue.identifier == "showOverviewController") {
          let secondView = segue.destination as! OverviewController
          let object = sender as! TopicModel
           secondView.cellId = object.id
       }
    }
    
    //Configure styling of the UI List
    private func listLayout() -> UICollectionViewCompositionalLayout {
            var listConfiguration = UICollectionLayoutListConfiguration(appearance: .grouped)
            listConfiguration.showsSeparators = false
            listConfiguration.backgroundColor = .clear
            return UICollectionViewCompositionalLayout.list(using: listConfiguration)
        }
    
    
}
