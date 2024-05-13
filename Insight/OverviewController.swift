//
//  OverviewController.swift
//  Insight
//
//  Created by Theo Kramer on 13.05.24.
//

import Foundation
import UIKit

class OverviewController: UIViewController {
    var cellId: String = ""
    @IBAction func goNextClicked(_ sender: Any) {
        performSegue(withIdentifier: "showViewController", sender: cellId)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if (segue.identifier == "showViewController") {
          let secondView = segue.destination as! ViewController
          let object = sender as! String
           secondView.cellId = object
       }
    }
}
