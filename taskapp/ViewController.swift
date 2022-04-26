//
//  ViewController.swift
//  taskapp
//
//  Created by 小野 拓人 on 2022/04/18.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var search: UISearchBar!
    @IBOutlet weak var categorySearchTextField: UITextField!
    
    //Realmインスタンスを取得する
    var realm = try! Realm()
    var category: Category!
    
    var pickerView: UIPickerView = UIPickerView()
    
    var categoryList = try! Realm().objects(Category.self).sorted(byKeyPath: "ID", ascending: true)
    
    var categoryListCount:Int = 0
    var searchCategory = ["全てのカテゴリー"]
    
    // DB内のタスクが格納されるリスト。
    // 日付の近い順でソート：昇順
    //以降内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        
        // Do any additional setup after loading the view.
        tableView.fillerRowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        
        search.delegate = self
        
        categorySearchTextField.inputView = pickerView
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        
    }
    //検索機能　ーーーーーーーここからーーーーーーー
    func setupSearchBar(){
        search.delegate = self
    }
    
    
    //  検索バーに入力があったら呼ばれる
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.categorySearchTextField.text = searchCategory[0]
        guard let searchText = search.text else {
            return
        }
        if searchText == "" {
            taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true)
            tableView.reloadData()
            return
        } else {
            let predicate = NSPredicate(format: "kategoriInput = %@", searchText)
            taskArray = realm.objects(Task.self).filter(predicate)
            
            tableView.reloadData()
        }
    }
    //検索機能はーーーーーーーーここまでーーーーーー
    
    // segue で画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    // UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // 表示する列数
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // アイテム表示個数を返す
        return searchCategory.count
    }
    
    // UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // 表示する文字列を返す
        return searchCategory[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        self.categorySearchTextField.text = searchCategory[row]
        
        guard let categoryText = categorySearchTextField.text else {
            return
        }
        if categoryText == "" {
            taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true)
            search.text = categoryText
            tableView.reloadData()
        } else if categoryText == "全てのカテゴリー" {
            taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true)
            search.text = ""
            tableView.reloadData()
            
        } else {
            let predicate = NSPredicate(format: "kategoriInput = %@", categoryText)
            search.text = categoryText
            taskArray = realm.objects(Task.self).filter(predicate)
            
            tableView.reloadData()
        }
    }
    
    //入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        
        if categoryList.count != 0 {
            self.searchCategory = ["全てのカテゴリー"]
            categoryListCount = categoryList.count
            for i in 0..<categoryListCount {
                searchCategory.append(categoryList[i].kategori)
            }
        }
    }
    
    //データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    //各セルの内容を返すメソッド
    func tableView(_ tableview: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        //Cellに値を設定する --- ここから ---
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        // --- ここまで追加 ---
        
        return cell
    }
    
    //各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    //セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    //Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            //削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            //ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            //データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            //未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request  in requests {
                    print("/--------------")
                    print(request)
                    print("/--------------")
                }
            }
        }
    }
    
    
    @objc func dismissKeyboard() {
        // キーボードを閉じる
        view.endEditing(true)
    }
}

