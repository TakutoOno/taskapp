//
//  CategoryViewController.swift
//  taskapp
//
//  Created by 小野 拓人 on 2022/04/21.
//

import UIKit
import RealmSwift

class CategoryViewController: UIViewController {
    
    @IBOutlet weak var categoryCreateTextField: UITextField!
    
    let realm = try! Realm()
    var category: Category!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self,action: #selector(dismissKeyboard))
        
        categoryCreateTextField.text = self.category.kategori
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        try! realm.write {
            self.category.kategori = self.categoryCreateTextField.text!
            self.realm.add(self.category, update: .modified)
        }
        
        super.viewWillDisappear(animated)
    }
    
    @objc func dismissKeyboard() {
        //キーボードを閉じる
        view.endEditing(true)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
