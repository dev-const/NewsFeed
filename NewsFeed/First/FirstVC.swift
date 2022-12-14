import UIKit
import RealmSwift

final class FirstVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var networkManagerNewsApi = NetworkManagerNewsApi()
    private var imagesArray = [UIImage?]()
    private var postsArray = [CurrentPostModel]()
    
    //MARK: Realm
    
    private var realm = try! Realm()
    private var savedPosts = [PostRealmModel]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate   = self
        self.searchBar.delegate   = self
    }
    
    //MARK: Запрос в сеть
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        networkManagerNewsApi.fetchData(viewController: self, urlString: networkManagerNewsApi.createURL(countryCodes: CountrysCodes.UnitedStates.rawValue)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let articles):
                self.reloadPostsArray(articles: articles)
                self.tableView.reloadData()
            case .failure:
                    self.present(СreateAlertController().createErrorAlert(), animated: true)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.animateTableView()
    }
    
    //MARK: ReadVC - WebView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath == tableView.indexPathForSelectedRow else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let readVC = storyboard.instantiateViewController(identifier: "ReadVC") as? ReadVC else { return }
        readVC.stringUrl = postsArray[indexPath.item].url ?? ""
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(readVC, animated: true)
        }
    }
    
    //MARK: FirstVC - SettingsVC
    
    @IBAction func settingsBarButton(_ sender: UIBarButtonItem) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "SettingsVC") else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

//MARK: Extension - TableView

extension FirstVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FirstCell", for: indexPath) as! FirstVCCell
        
        cell.titleText.text = postsArray[indexPath.item].title
        cell.authorText.text = {
            if let author = postsArray[indexPath.item].author {
                return "\(author)"
            } else {
                return "Author unknown"
            }
        }()
        cell.imagePost.downloadImagePost(stringUrl: postsArray[indexPath.item].urlToImage ?? "")
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.0
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let readLaterAction = UIContextualAction(
            style: .normal,
            title: nil) { [weak self] (action, view, completion) in
                
                if let currentArticle = self?.postsArray[indexPath.item] {
                    
                    let savedPost = PostRealmModel()
                    savedPost.date = currentArticle.publishedAt ?? ""
                    savedPost.title = currentArticle.title ?? ""
                    savedPost.shortContent = currentArticle.content ?? ""
                    savedPost.urlToImage = currentArticle.urlToImage ?? ""
                    savedPost.source = currentArticle.sourceName ?? ""
                    savedPost.url = currentArticle.url ?? ""
                    
                    try! self?.realm.write{
                        self?.realm.add(savedPost)
                    }
                    completion(true)
                }
            }
        
        readLaterAction.backgroundColor = UIColor.blackCustom
        readLaterAction.image = UIImage(systemName: "bookmark")
        let configuration = UISwipeActionsConfiguration(actions: [readLaterAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

//MARK: Extension - ReloadPosts

extension FirstVC {
    
    private func reloadPostsArray(articles: [Article]) {
        self.postsArray = articles.compactMap({ CurrentPostModel(sourceName: $0.source?.name,
                                                                 author: $0.author,
                                                                 title: $0.title,
                                                                 articleDescription: $0.articleDescription,
                                                                 url: $0.url,
                                                                 urlToImage: $0.urlToImage,
                                                                 publishedAt: $0.publishedAt,
                                                                 content: $0.content)
        })
    }
}

//MARK: Extension - UISearchBarDelegate

extension FirstVC: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if let _ = searchBar.text {
            NetworkManagerNewsApi().fetchData(viewController: self, urlString: networkManagerNewsApi.createURL(phrase: searchBar.text!)) { [weak self] result in
                switch result {
                case .success(let articles):
                    self?.reloadPostsArray(articles: articles)
                case .failure: break
                }
            }
            searchBar.searchTextField.resignFirstResponder()
        }
    }
}
