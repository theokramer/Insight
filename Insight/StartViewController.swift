import UIKit
import CoreData

extension TopicModel {
    static var topicData: [TopicModel] = []
}

class StartViewController: UICollectionViewController {
    
    typealias DataSource = UICollectionViewDiffableDataSource<Int, String>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, String>
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        configureCollectionView()
        configureAddTopicButton()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }
    
    private func configureNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.titleTextAttributes = [.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 20)]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 20)]
        }
        
        navigationController?.navigationBar.tintColor = .black
    }
    
    private func configureCollectionView() {
        collectionView.collectionViewLayout = createListLayout()
        collectionView.backgroundColor = .clear
    }
    
    private func configureAddTopicButton() {
        let addTopicButton = UIButton(type: .system)
        addTopicButton.setTitle("Add Topic", for: .normal)
        addTopicButton.setTitleColor(.white, for: .normal)
        addTopicButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
        addTopicButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = UIColor(red: 78/255, green: 162/255, blue: 196/255, alpha: 1.0)
            configuration.cornerStyle = .large
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            addTopicButton.configuration = configuration
        } else {
            addTopicButton.backgroundColor = UIColor(red: 78/255, green: 162/255, blue: 196/255, alpha: 1.0)
            addTopicButton.layer.cornerRadius = 12
            addTopicButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        }
        
        addTopicButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addTopicButton)
        
        NSLayoutConstraint.activate([
            addTopicButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addTopicButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }
    
    private func loadData() {
        TopicModel.topicData.removeAll()
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            guard let items = try context.fetch(Topic.fetchRequest()) as? [Topic] else { return }
            TopicModel.topicData = items.map {
                TopicModel(id: $0.wrappedId, name: $0.wrappedName.isEmpty ? "Untitled" : $0.wrappedName)
            }
        } catch {
            print("Error fetching data: \(error)")
        }
        
        configureDataSource()
    }
    
    private func refreshData() {
        // Refresh the data and apply the new snapshot
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(TopicModel.topicData.map { $0.id })
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { (cell, indexPath, itemIdentifier) in
            var contentConfiguration = cell.defaultContentConfiguration()
            if let topic = TopicModel.topicData.first(where: { $0.id == itemIdentifier }) {
                contentConfiguration.text = topic.name
            }
            cell.contentConfiguration = contentConfiguration
        }
        
        dataSource = DataSource(collectionView: collectionView) { (collectionView, indexPath, itemIdentifier) in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        refreshData()
    }
    
    private func createListLayout() -> UICollectionViewCompositionalLayout {
        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .grouped)
        return UICollectionViewCompositionalLayout.list(using: listConfiguration)
    }
    
    @objc private func buttonTapped() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let newTopic = Topic(context: context)
        newTopic.id = UUID().uuidString
        newTopic.name = ""
        
        DispatchQueue.main.async {
            do {
                try context.save()
                self.performSegue(withIdentifier: "showOverviewController", sender: TopicModel(id: newTopic.id!, name: newTopic.name!))
            } catch {
                print("Error saving data: \(error)")
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showOverviewController", sender: TopicModel.topicData[indexPath.item])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOverviewController",
           let destination = segue.destination as? OverviewController,
           let topic = sender as? TopicModel {
            destination.cellId = topic.id
        }
    }
    
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
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let topicToDelete = TopicModel.topicData[indexPath.item]
        
        TopicModel.topicData.remove(at: indexPath.item)
        
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(TopicModel.topicData.map { $0.id })
        dataSource.apply(snapshot, animatingDifferences: true)
        
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
