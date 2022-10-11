//
//  QuizController.swift
//  Trivia
//
//  Created by Spencer Kinsey-Korzym on 5/1/22.
//

import UIKit
import MultipeerConnectivity
import CoreMotion

class QuizController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MCSessionDelegate{
    
    @IBOutlet weak var players: UICollectionView!
    @IBOutlet weak var answerSelections: UICollectionView!
    @IBOutlet weak var question: UILabel!
    @IBOutlet weak var playersViewContainer: UIView!
    var isSinglePlayer = false
    var answers: [String]!
    var correctAnswer: String!
    var currentQuestionNumber: Int!
    var jsonData: Data!
    var json: Data!
    var selectedAnswer: IndexPath!
    var session: MCSession!
    var player: Player!
    var pitch = 0.0
    var roll = 0.0
    var startingPitch: Double?
    var startingRoll: Double?
    var isFinishedAnswering: Bool!
    var motionTimer: Timer!
    var zeroMotionTimer: Timer!
    var quiz: Quiz?
    @IBOutlet weak var loadingView: UIView!
    let coreMotionManager = CMMotionManager()
    var quizNum = 1
    var connectedPeers: [PlayerCell]!
    var gameTimer: Timer!
    var timerCount: Int! = 20
    @IBOutlet weak var timerLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        becomeFirstResponder()
        coreMotionManager.gyroUpdateInterval = 0.2
        isFinishedAnswering = false
        monitorEulerAngles()
        players.delegate = self
        players.dataSource = self
        answerSelections.delegate = self
        answerSelections.dataSource = self
        answers = ["","","",""]
        currentQuestionNumber = 0
        getJSONdata()
       // jsonData = readJson(named: "test")
//        loadQuiz(withQuestionNumber: currentQuestionNumber)
        
        if isSinglePlayer{
            //playersViewContainer.isHidden = true
            loadingView.isHidden = true
            gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(startGameTimer), userInfo: nil, repeats: true)
        }else{
            session.delegate = self
            player = MCViewController.getData()
            do{
                try session.send(JSONEncoder().encode(self.player.profileImageData), toPeers: session.connectedPeers, with: .reliable)
                print("player pic sent")
            }catch{}
            
        }
//        print(session.connectedPeers)
//        print(connectedPeers)
//        print(self.session.myPeerID)

        // Do any additional setup after loading the view.
    }
    @objc func startGameTimer(){
        if timerCount == 0{
            gameTimer.invalidate()
            self.timerLabel.text = "20"
            self.timerCount = 20
            if session != nil{
            try! session.send(JSONEncoder().encode("grade"), toPeers: session.connectedPeers, with: .reliable)
            }else{
                submitAnswer()
            }
        }else{
        timerCount -= 1
        self.timerLabel.text = String(timerCount)
        }
    }
    override var canBecomeFirstResponder: Bool{
        return true
    }
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
         
    }
    func radiansToDegrees(_ radians: Double) -> Double {
        return radians * (180.0 / Double.pi)
    }


    
    func monitorEulerAngles(){
        coreMotionManager.deviceMotionUpdateInterval = 5
        coreMotionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
        motionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(getMotionData), userInfo: nil, repeats: true)
        zeroMotionTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(zeroMotionSensor), userInfo: nil, repeats: true)
    }
    @objc func getMotionData(){
        if let data = coreMotionManager.deviceMotion{
            if !isFinishedAnswering{
                let quat = data.attitude.quaternion
                pitch = CGFloat(radiansToDegrees(atan2(2 * (quat.x * quat.w + quat.y * quat.z), 1 - 2 * quat.x * quat.x - 2 * quat.z * quat.z)))
                if startingPitch == nil{
                    self.startingPitch = pitch
                }
                if selectedAnswer != nil{
                    if pitch < startingPitch! - 20{
                        //print("up")
                        //          `      if selectedAnswer == IndexPath.init(item: 0, section: 1){
                        //                    answerSelections.visibleCells[0].backgroundColor = UIColor.yellow
                        //                    answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.opaqueSeparator
                        //                    selectedAnswer = IndexPath.init(item: 0, section: 0)
                        //                }`
                        switch selectedAnswer{
                        case IndexPath.init(item: 0, section: 1):
                            answerSelections.visibleCells[0].backgroundColor = UIColor.yellow
                            answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.opaqueSeparator
                            selectedAnswer = IndexPath.init(item: 0, section: 0)
                        case IndexPath.init(item: 1, section: 1):
                            answerSelections.visibleCells[1].backgroundColor = UIColor.yellow
                            answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.opaqueSeparator
                            selectedAnswer = IndexPath.init(item: 1, section: 0)
                        default:
                            break
                        }
                    } else if pitch > startingPitch! + 20{
                      //  print("down")
                        switch selectedAnswer{
                        case IndexPath.init(item: 0, section: 0):
                            answerSelections.visibleCells[2].backgroundColor = UIColor.yellow
                            answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.opaqueSeparator
                            selectedAnswer = IndexPath.init(item: 0, section: 1)
                        case IndexPath.init(item: 1, section: 0):
                            answerSelections.visibleCells[3].backgroundColor = UIColor.yellow
                            answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.opaqueSeparator
                            selectedAnswer = IndexPath.init(item: 1, section: 1)
                        default:
                            break
                        }
                    }else{
                       // print("none")
                    }
                    roll = CGFloat(radiansToDegrees(atan2(2 * (quat.y * quat.w + quat.x * quat.z), 1 - 2 * quat.y * quat.y - 2 * quat.z * quat.z)))
                    if startingRoll == nil{
                       // print("it is nil")
                        self.startingRoll = roll
                    }
                    if roll > startingRoll! + 30{
                        //print("right")
                        switch selectedAnswer{
                        case IndexPath.init(item: 0, section: 0):
                            answerSelections.visibleCells[1].backgroundColor = UIColor.yellow
                            answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.opaqueSeparator
                            selectedAnswer = IndexPath.init(item: 1, section: 0)
                        case IndexPath.init(item: 0, section: 1):
                            answerSelections.visibleCells[3].backgroundColor = UIColor.yellow
                            answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.opaqueSeparator
                            selectedAnswer = IndexPath.init(item: 1, section: 1)
                        default:
                            break
                        }
                    }
                    if roll < startingRoll! - 30{
                       // print("left")
                        switch selectedAnswer{
                        case IndexPath.init(item: 1, section: 0):
                            answerSelections.visibleCells[0].backgroundColor = UIColor.yellow
                            answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.opaqueSeparator
                            selectedAnswer = IndexPath.init(item: 0, section: 0)
                        case IndexPath.init(item: 1, section: 1):
                            answerSelections.visibleCells[2].backgroundColor = UIColor.yellow
                            answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.opaqueSeparator
                            selectedAnswer = IndexPath.init(item: 0, section: 1)
                        default:
                            break
                        }
                    }
                    
                    let acc = data.userAcceleration.z
                    if acc >= 0.9 || acc <= -0.7{
                        self.answerSelections.cellForItem(at: selectedAnswer)?.backgroundColor = UIColor.green
                        self.answerSelections.isUserInteractionEnabled = false
                        (players.visibleCells[0] as! PlayerCell).state.image = UIImage(systemName: "checkmark.circle")
                        (players.visibleCells[0] as! PlayerCell).state.tintColor = UIColor.green
                        if !isSinglePlayer{
                            if self.connectedPeers.allSatisfy { $0.state.image ==
                                UIImage(systemName: "checkmark.circle")
                            }{
                                try! session.send(JSONEncoder().encode("grade"), toPeers: session.connectedPeers, with: .reliable)
                            }
                            print("sending message")
                            try! self.session.send(JSONEncoder().encode("done"), toPeers: session.connectedPeers, with: .reliable)
                        }
                        
                    }
                    
                }
            }
        }
    }
    
    @objc func zeroMotionSensor(){
        if let data = coreMotionManager.deviceMotion{
            let quat = data.attitude.quaternion
            self.startingPitch = CGFloat(radiansToDegrees(atan2(2 * (quat.x * quat.w + quat.y * quat.z), 1 - 2 * quat.x * quat.x - 2 * quat.z * quat.z)))
            self.startingRoll = CGFloat(radiansToDegrees(atan2(2 * (quat.y * quat.w + quat.x * quat.z), 1 - 2 * quat.y * quat.y - 2 * quat.z * quat.z)))
        }
    }
    func stopTimers(){
        motionTimer.invalidate()
        zeroMotionTimer.invalidate()
    }
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake{
            //print("shaking")
            var randomIndex = Int.random(in: 0...3)
            while (answerSelections.visibleCells[randomIndex] as! AnswerCell).backgroundColor != UIColor.opaqueSeparator{
              // print("need to change ")
                randomIndex = Int.random(in: 0...3)
            }
            let selectedCell = answerSelections.visibleCells[randomIndex] as! AnswerCell
            for cell in answerSelections.visibleCells {
                cell.backgroundColor = UIColor.opaqueSeparator
            }
            selectedCell.backgroundColor = UIColor.yellow
            selectedAnswer = answerSelections.indexPath(for: selectedCell)
        }
    }
    
    func loadQuiz(withQuestionNumber num: Int){
        print(self.quiz)
        //        if let data = jsonData{
        DispatchQueue.main.async(execute: { [unowned self] in
            if let quizObj = self.quiz{
                print("number of questions: \(quizObj.numberOfQuestions)")
                print("Questions:")
                print("     \(quizObj.questions[num].questionSentence)")
                print("         A: \(quizObj.questions[num].options.A)")
                print("         B: \(quizObj.questions[num].options.B)")
                print("         C: \(quizObj.questions[num].options.C)")
                print("         D: \(quizObj.questions[num].options.D)")
                print("     \(quizObj.questions[num].correctOption)")
                question.text = "Question \(num+1)/\(quizObj.numberOfQuestions) \(quizObj.questions[num].questionSentence)"
                answers[0] = "A) \(quizObj.questions[num].options.A)"
                answers[1] = "B) \(quizObj.questions[num].options.B)"
                answers[2] = "C) \(quizObj.questions[num].options.C)"
                answers[3] = "D) \(quizObj.questions[num].options.D)"
                correctAnswer = quizObj.questions[num].correctOption
                self.navigationItem.title = quizObj.topic
                self.answerSelections.reloadData()
                
            }
        })
        
        
        //}
    }

    func getJSONdata(){
        let URLString = "https://www.people.vcu.edu/~ebulut/jsonFiles/quiz\(quizNum).json"
        let URL = URL(string: URLString)
         URLSession.shared.dataTask(with: URL!) { data, response, error in
            guard let data = data, error == nil else{ return }
            do{
                self.quiz = try JSONDecoder().decode(Quiz.self, from: data)
            }catch{}
             self.loadQuiz(withQuestionNumber: self.currentQuestionNumber)
        }.resume()

    }
//    func readJson(named name:String)->Data?{
//        do{
//            if let filePath = Bundle.main.path(forResource: name, ofType: "json"){
//                let fileURL = URL(fileURLWithPath: filePath)
//                let data  = try Data(contentsOf: fileURL)
//                return data
//            }
//        } catch {
//            print("error \(error)")
//        }
//        return nil
//    }
    func parse(jsonData: Data){
        do{
            let decodedData = try JSONDecoder().decode(Quiz.self, from: jsonData)
            self.quiz =  decodedData
        } catch {
           // print("error \(error)")
        }
       
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.players{
            return 4
        }
        else{
            return 2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.players{
            let cell = players.dequeueReusableCell(withReuseIdentifier: "player-cell", for: indexPath) as! PlayerCell
            cell.isUserInteractionEnabled = false
            if indexPath.item > 0 {
                let playerImage = UIImage(systemName: "person")!
                let playerState = UIImage(systemName: "xmark.circle")!
                cell.configure(with: CategoryItem(image: playerImage, state: playerState))
                cell.state.tintColor = UIColor.red
            }else{
                cell.configure(with: CategoryItem(image: (UIImage(data:MCViewController.getData()!.profileImageData) ?? UIImage(systemName: "person"))!, state: UIImage(systemName: "ellipsis.circle")!))
                cell.state.tintColor = UIColor.systemOrange
            }
            return cell
        }
        else{
            let cell = answerSelections.dequeueReusableCell(withReuseIdentifier: "answer-cell", for: indexPath) as! AnswerCell
            
            if indexPath.section == 0{
                cell.configureAnswer(with: answers[indexPath.item], isAnswer: isAnswerCorrect(indexPath.item))
            }else{
                cell.configureAnswer(with: answers[indexPath.section + indexPath.item + 1], isAnswer: isAnswerCorrect(indexPath.section + indexPath.item + 1))
            }
            
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath) as! AnswerCell
        for cell in collectionView.visibleCells {
            cell.backgroundColor = UIColor.opaqueSeparator
        }
        if selectedAnswer == indexPath{
            self.connectedPeers = []
            selectedCell.backgroundColor = UIColor.green
            self.answerSelections.isUserInteractionEnabled = false
            (players.visibleCells[0] as! PlayerCell).state.image = UIImage(systemName: "checkmark.circle")
            (players.visibleCells[0] as! PlayerCell).state.tintColor = UIColor.green
            if !isSinglePlayer{
                self.connectedPeers = []
                for i in 0...session.connectedPeers.count{
                    self.connectedPeers.append(self.players.visibleCells[i] as! PlayerCell)
                }
                
                if (self.connectedPeers.allSatisfy { $0.state.image ==
                    UIImage(systemName: "checkmark.circle")
                }){
                    try! session.send(JSONEncoder().encode("grade"), toPeers: session.connectedPeers, with: .reliable)
                }
                print("sending message")
                try! self.session.send(JSONEncoder().encode("done"), toPeers: session.connectedPeers, with: .reliable)
                
            }else{
                submitAnswer()
            }
        }else{
            selectedCell.backgroundColor = UIColor.yellow
        }
        selectedAnswer = indexPath
        
        
    }
    func showAnswer(){
        if self.selectedAnswer != nil{
            let cell = self.answerSelections.cellForItem(at: self.selectedAnswer) as! AnswerCell
            if cell.isCorrectAnswer == false{
                cell.backgroundColor = UIColor.red
            }
        }
        if gameTimer != nil ||  gameTimer.isValid{
            gameTimer.invalidate()
        }
        self.question.text = "The correct answer was \(correctAnswer!)"
    }
    func submitAnswer(){
        showAnswer()
        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(loadNextQuestion), userInfo: nil, repeats: false)

        
    }
    @objc func loadNextQuestion(){
        if session != nil{
            for i in 0...session.connectedPeers.count{
                (self.players.visibleCells[i] as! PlayerCell).state.image = UIImage(systemName: "ellipsis.circle")
                (self.players.visibleCells[i] as! PlayerCell).state.tintColor = UIColor.systemOrange
            }
            
        }else{
            (self.players.visibleCells[0] as! PlayerCell).state.image = UIImage(systemName: "ellipsis.circle")
            (self.players.visibleCells[0] as! PlayerCell).state.tintColor = UIColor.systemOrange
        }
        if quizNum == 4{
            quizNum = 0
            currentQuestionNumber = 0
        }
        if currentQuestionNumber == self.quiz!.numberOfQuestions - 1{
            print(currentQuestionNumber)
            quizNum += 1
            currentQuestionNumber = 0
            getJSONdata()
        }else{
            currentQuestionNumber += 1
            loadQuiz(withQuestionNumber: currentQuestionNumber)
        }
        isFinishedAnswering = true
        stopTimers()
       
        for cell in answerSelections.visibleCells {
            cell.backgroundColor = UIColor.opaqueSeparator
        }
        selectedAnswer = nil
        self.answerSelections.isUserInteractionEnabled = true
        self.timerLabel.text = "20"
        self.timerCount = 20
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(startGameTimer), userInfo: nil, repeats: true)
        
    }
    func isAnswerCorrect(_ indexOfAnswer: Int)->Bool{
        var correctAnswerIndex = -1
        switch(correctAnswer){
        case "A":
            correctAnswerIndex = 0
        case "B":
            correctAnswerIndex = 1
        case "C":
            correctAnswerIndex = 2
        case "D":
            correctAnswerIndex = 3
        default:
            break
        }
        return indexOfAnswer == correctAnswerIndex
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.players{
            return 1
        }else{
            return 2
            
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let numberOfCells = CGFloat(collectionView.numberOfItems(inSection: 0))
        let cellWidth = (collectionView.frame.size.width - 40) / 4
        let totalCellWidth = cellWidth * numberOfCells
        
        if collectionView == self.players{
            
            let totalSpacingWidth = CGFloat(10 * (collectionView.numberOfItems(inSection: 0) - 1))
            
            let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
            let rightInset = leftInset
            
            return UIEdgeInsets(top: 10, left: leftInset, bottom: 10, right: rightInset)
        }else{
            if section == 0{
                return UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
            }else{
                return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }
        }

    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.players{
        let width = (collectionView.frame.size.width - 40) / 4
            let height = collectionView.frame.size.height - 20
        return CGSize(width: width , height: height)
        }else{
            let width = (collectionView.frame.size.width - 10)/2
            let height = (collectionView.frame.size.height - 5)/2

            return CGSize(width: width , height: height)
        }

    }
    //MARK: For MCSession
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("incoming data")
        print(data)
        DispatchQueue.main.async(execute:{
            if data.count >= 100{
                if let imageData = try? JSONDecoder().decode(Data.self, from: data) as Data{
                    print("is user")
                    let playerIndex = session.connectedPeers.firstIndex {
                        $0.displayName == peerID.displayName
                    }
                    print(playerIndex)
                    let totalPlayers = session.connectedPeers.count
                    if totalPlayers == 3{
                        if (self.players.visibleCells[0] as! PlayerCell).image
                            != UIImage(systemName: "person")
                            && (self.players.visibleCells[1] as! PlayerCell).image
                            != UIImage(systemName: "person")
                            && (self.players.visibleCells[2] as! PlayerCell).image
                            != UIImage(systemName: "person")
                            && (self.players.visibleCells[3] as! PlayerCell).image
                            != UIImage(systemName: "person"){
                            try! session.send(JSONEncoder().encode("loaded"), toPeers: session.connectedPeers, with: .reliable)
                        }
                    }else if totalPlayers == 2{
                        if (self.players.visibleCells[0] as! PlayerCell).image
                            != UIImage(systemName: "person")
                            && (self.players.visibleCells[1] as! PlayerCell).image
                            != UIImage(systemName: "person")
                            && (self.players.visibleCells[2] as! PlayerCell).image
                            != UIImage(systemName: "person"){
                            try! session.send(JSONEncoder().encode("loaded"), toPeers: session.connectedPeers, with: .reliable)
                        }
                    }else{
                        try! session.send(JSONEncoder().encode("loaded"), toPeers: session.connectedPeers, with: .reliable)
                    }
                    let cell = self.players.visibleCells[playerIndex! + 1 ] as! PlayerCell
                    print("COUNT: \(session.connectedPeers.count)")
                    cell.image.image = UIImage(data: imageData)
                    cell.state.image = UIImage(systemName: "ellipsis.circle")!
                    cell.state.tintColor = UIColor.systemOrange
                    
                }
            }
            
            if let str = try? JSONDecoder().decode(String.self, from: data) {
           
                if str == "done"{
                    let playerIndex = self.session.connectedPeers.firstIndex { $0.displayName == peerID.displayName
                    }
                    
                    let playerCell = self.players.visibleCells[playerIndex! + 1] as! PlayerCell
                    playerCell.state.image = UIImage(systemName: "checkmark.circle")
                    playerCell.state.tintColor = UIColor.green
                    self.connectedPeers = []
                    for i in 0...session.connectedPeers.count{
                        self.connectedPeers.append(self.players.visibleCells[i] as! PlayerCell)
                    }
                    if self.connectedPeers.allSatisfy { $0.state.image ==
                        UIImage(systemName: "checkmark.circle")
                    }{
                        try! session.send(JSONEncoder().encode("grade"), toPeers: session.connectedPeers, with: .reliable)
                    }
                    
                }else if str == "grade"{
                    self.submitAnswer()
                }else{
                    self.loadingView.isHidden = true
                    self.gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.startGameTimer), userInfo: nil, repeats: true)
                }
            }
            
            
        })
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state{
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
            
        @unknown default:
            fatalError()
        }
      
        
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }


}
struct Quiz: Codable{
    let numberOfQuestions: Int
    let questions: [Question]
    let topic: String
}
struct Question:Codable{
    let number: Int
    let questionSentence: String
    let options: Option
    let correctOption: String
}
struct Option: Codable{
    let A: String
    let B: String
    let C: String
    let D:String
    
}
