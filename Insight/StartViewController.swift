import Foundation
import UIKit
import CoreData

extension TopicModel {
    // Array with all Topics. It gets fetched from Core Data
    static var topicData: [TopicModel] = []
}

class StartViewController: UICollectionViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, String>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, String>
    
    var dataSource: DataSource!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Button erstellen
        let addTopicButton = UIButton(type: .system)
        addTopicButton.setTitle("Add Topic", for: .normal)
        
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = UIColor(red: 78 / 255, green: 162 / 255, blue: 196 / 255, alpha: 1.0)
            configuration.cornerStyle = .large
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            addTopicButton.configuration = configuration
        } else {
            addTopicButton.backgroundColor = .systemBlue
            addTopicButton.layer.cornerRadius = 12 // Large corner style
            addTopicButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            addTopicButton.backgroundColor = UIColor(red: 78 / 255, green: 162 / 255, blue: 196 / 255, alpha: 1.0) // RGB for a custom color
        }
        addTopicButton.setTitleColor(.white, for: .normal)
        addTopicButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
        
        addTopicButton.translatesAutoresizingMaskIntoConstraints = false
        addTopicButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        // Button zur Ansicht hinzufügen
        self.view.addSubview(addTopicButton)
        
        // Layout für den Button festlegen
        NSLayoutConstraint.activate([
            addTopicButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            addTopicButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
        ])
        
        TopicModel.topicData.removeAll()
        
        // Create List of Topic Names
        let listLayout = listLayout()
        collectionView.collectionViewLayout = listLayout
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            // Try to get all Topics in Core Data
            guard let items = try context.fetch(Topic.fetchRequest()) as? [Topic] else {
                return
            }
            // TODO: Update this, so we don't need the removeAll() anymore -> Improve Runtime
            for myTopic in items {
                // Add all Topics to the Array
                let newTopic = TopicModel(id: myTopic.wrappedId, name: myTopic.wrappedName == "" ? "Ohne Titel" : myTopic.wrappedName)
                TopicModel.topicData.append(newTopic)
            }
        } catch {
            print("error-Fetching data")
        }
        
        // Configure Cells in List with Topic Names
        let cellRegistration = UICollectionView.CellRegistration { (cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: String) in
            let topic = TopicModel.topicData[indexPath.item]
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = topic.name
            cell.contentConfiguration = contentConfiguration
        }
        
        dataSource = DataSource(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, itemIdentifier: String) in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        // Connect topicData Array to the UI List
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(TopicModel.topicData.map { $0.id })
        dataSource.apply(snapshot)
        collectionView.dataSource = dataSource
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white // Customize the background color
            appearance.titleTextAttributes = [.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 20)]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = UIColor.white
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 20)]
        }
        
        self.navigationController?.navigationBar.tintColor = .black
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showOverviewController", sender: TopicModel.topicData[indexPath.item])
    }
    
    // Transfer ID of tapped Cell
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showOverviewController") {
            let secondView = segue.destination as! OverviewController
            let object = sender as! TopicModel
            secondView.cellId = object.id
        }
    }
    
    // Let the User add new Topic
    @objc func buttonTapped() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let id = UUID().uuidString
        let name = ""
        let newData = Topic(context: context)
        newData.id = id
        newData.name = name
        DispatchQueue.main.async {
            do {
                try context.save()
                self.performSegue(withIdentifier: "showOverviewController", sender: TopicModel.init(id: id, name: name))
            } catch {
                print("error-saving data")
            }
        }
    }
    
    // Configure styling of the UI List
    private func listLayout() -> UICollectionViewCompositionalLayout {
        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .grouped)
        listConfiguration.showsSeparators = false
        listConfiguration.backgroundColor = .clear
        return UICollectionViewCompositionalLayout.list(using: listConfiguration)
    }
    
    // Enable swipe actions
    func collectionView(_ collectionView: UICollectionView, trailingSwipeActionsConfigurationForItemAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            self?.deleteTopic(at: indexPath)
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .red
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
    
    private func deleteTopic(at indexPath: IndexPath) {
        // Get the context
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        // Find the topic to delete
        let topicToDelete = TopicModel.topicData[indexPath.item]
        
        // Remove the topic from the data source array
        TopicModel.topicData.remove(at: indexPath.item)
        
        // Create a snapshot and apply it to update the UI
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(TopicModel.topicData.map { $0.id })
        dataSource.apply(snapshot, animatingDifferences: true)
        
        // Remove the topic from Core Data
        let fetchRequest: NSFetchRequest<Topic> = Topic.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", topicToDelete.id)
        
        do {
            let items = try context.fetch(fetchRequest)
            if let itemToDelete = items.first {
                context.delete(itemToDelete)
                try context.save()
            }
        } catch {
            print("Failed to delete topic: \(error)")
        }
    }
}
