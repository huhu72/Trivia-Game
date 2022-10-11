//
//  ViewController.swift
//  Trivia
//
//  Created by Spencer Kinsey-Korzym on 4/26/22.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var gameSelection: UISegmentedControl!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func startQuiz(_ sender: Any) {
        switch gameSelection.selectedSegmentIndex{
        case 0:
            performSegue(withIdentifier: "singlePlayer", sender: self)
        case 1:
            performSegue(withIdentifier: "multiplayer", sender: self)
        default:
            break
        }
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch( segue.identifier){
        case "multiplayer":
            let destinationVC = segue.destination as! MCViewController
        case "singlePlayer":
            let destinationVC = segue.destination as! QuizController
            destinationVC.isSinglePlayer = true
        default:
            break
        }
    }
}


