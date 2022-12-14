import UIKit

final class RateVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var currencyRatesLabel: UILabel!
    
    private var dataArray = [String: Double]()
    private var filteredData = [String: Double]()
    private var networkManagerCoinLayer = NetworkManagerCoinLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        networkManagerCoinLayer.fetchDataRates(viewController: self) { [weak self] currentRate in
            guard let self = self else { return }
            self.dataArray = currentRate
            self.filteredData = self.dataArray
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.animateTableView()
    }
    
    //MARK: RateVC - SettingsVC
    
    @IBAction func SettingsBarButton(_ sender: UIBarButtonItem) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "SettingsVC") else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}


//MARK: Extension - TableView

extension RateVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RateCell", for: indexPath) as! RateViewCell
        
        let values = Array(filteredData.values)
        let keys = Array(filteredData.keys)
        
        cell.shortNameRate.text = String(keys[indexPath.row])
        cell.valueRate.text = String(values[indexPath.row])
        if let safeText = cell.shortNameRate.text {
            cell.imageIcon.downloadImageCoin(shortName: safeText)
        }

        cell.selectionStyle = .none
        return cell
    }
}

//MARK: Extension - SearchBar

extension RateVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            filteredData = dataArray
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } else {
            
            filteredData = [:]
            for word in dataArray.keys {
                
                if word.uppercased().contains(searchText.uppercased()) {
                    filteredData = dataArray.filter({ $0.key.contains(word) })
                }
            }
            self.tableView.animateTableView()
        }
    }
}
