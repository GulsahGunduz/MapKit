
import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var titleArr = [String]()
    var idArr = [UUID]()
    
    var chosenTitle = ""
    var chosenTitleID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(AddButton))
        
        GetData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(GetData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func GetData(){
        titleArr.removeAll(keepingCapacity: false)
        idArr.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(request)
            if results.count > 0{
                for item in results as! [NSManagedObject]{ 
                    
                    if let title = item.value(forKey: "title") as? String{
                        titleArr.append(title)
                    }
                    if let id = item.value(forKey: "id") as? UUID{
                        idArr.append(id)
                    }
                    tableView.reloadData()
                }
            }
        }catch{
            print("error")
        }
    }
    
    @objc func AddButton(){
        chosenTitle = ""
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArr[indexPath.row]
        chosenTitleID = idArr[indexPath.row]
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toMapVC"{
            let destination = segue.destination as! MapVC
            destination.selectedTitle = chosenTitle
            destination.selectedTitleID = chosenTitleID
        }
    }
}



