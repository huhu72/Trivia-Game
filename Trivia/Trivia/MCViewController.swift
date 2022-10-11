//
//  ViewController.swift
//  Trivia
//
//  Created by Spencer Kinsey-Korzym on 4/26/22.
//

import UIKit
import MultipeerConnectivity

class MCViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate,MCNearbyServiceAdvertiserDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    var session: MCSession!
    var peer: MCPeerID!
    var browser: MCBrowserViewController!
    var advertiser: MCNearbyServiceAdvertiser!
    var connectedPeers = [String]()
    var alertController: UIAlertController!
    var alertAction: UIAlertAction!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var joinBtn: UIButton!
    @IBOutlet weak var hostBtn: UIButton!
    @IBOutlet weak var joinedPlayers: UITableView!
    @IBOutlet weak var joinedPlayersLabel: UILabel!
    @IBOutlet weak var startQuizBtn: UIButton!
    @IBOutlet weak var profileImage: UIImageView!
    var isHosting: Bool = false
    var startGame:Bool!
    var player: Player!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.joinedPlayers.delegate = self
        self.joinedPlayers.dataSource = self
        self.startGame = false
        self.startQuizBtn.isUserInteractionEnabled = false
        if let userInfo = MCViewController.getData(){
            self.player = userInfo
            self.profileImage.image = UIImage(data: userInfo.profileImageData)
            self.name.text = userInfo.name
        }
        print("COUNT: \(true && false)")
       
        // Do any additional setup after loading the view.
    }
    @IBAction func uploadImage(_ sender: UITapGestureRecognizer) {
        profileImage = sender.view as? UIImageView
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            present(imagePicker, animated: true)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        profileImage!.image = image
        profileImage!.contentMode = .scaleAspectFill
        dismiss(animated: true, completion: nil)
    }
    @IBAction func host(_ sender: Any) {
        if name.text!.isEmpty{
            alertController = UIAlertController(title: "ERROR", message: "You must provide a name!", preferredStyle: .alert)
            alertAction = UIAlertAction(title: "Okay", style: .default, handler: { _ in })
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
            
        }else if profileImage.image == UIImage(systemName: "person.badge.plus"){
            alertController = UIAlertController(title: "ERROR", message: "Please add a profile image", preferredStyle: .alert)
            alertAction = UIAlertAction(title: "Okay", style: .default, handler: { _ in })
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
        }else{
            isHosting = true
            initializeSession(name: name.text!)
            startHosting()
            initializePlayer()
            joinedPlayers.isHidden = false
            joinedPlayers.isUserInteractionEnabled = false
            self.startQuizBtn.isUserInteractionEnabled = true
            MCViewController.saveData(data: self.player)
        }
    }
    
    @IBAction func join(_ sender: Any) {
        isHosting = false
        startQuizBtn.isUserInteractionEnabled = false
        if name.text!.isEmpty{
            self.joinedPlayers.reloadData()
            alertController = UIAlertController(title: "ERROR", message: "You must provide a name!", preferredStyle: .alert)
            alertAction = UIAlertAction(title: "Okay", style: .default, handler: { _ in })
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
            
        }else if profileImage.image == UIImage(systemName: "person.badge.plus"){
            alertController = UIAlertController(title: "ERROR", message: "Please add a profile image", preferredStyle: .alert)
            alertAction = UIAlertAction(title: "Okay", style: .default, handler: { _ in })
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
        }
        else{
            initializeSession(name: name.text!)
            initializePlayer()
            joinSession()
            MCViewController.saveData(data: self.player)
        }
       
    }
    func initializePlayer(){
        self.player = Player(name: name.text!, imageData: profileImage.image!.pngData()!)
    }
    @IBAction func startQuiz(_ sender: Any) {
         alertController = UIAlertController(title: "ERROR!", message: "You must have at least 1 person in the lobby to start!", preferredStyle: .alert)
        alertAction = UIAlertAction(title: "Okay", style: .default)
        alertController.addAction(alertAction)
        if self.connectedPeers.isEmpty {
            present(alertController, animated: true)
        }else{
            startGame = true
            performSegue(withIdentifier: "start-quiz", sender: self)
            print("sending from startQuiz")
            do{
                try self.session.send(JSONEncoder().encode(startGame), toPeers: session.connectedPeers, with: .reliable)
            }catch let error as NSError{
                print(error.localizedDescription)
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! QuizController
        destinationVC.session = self.session
    }
    
//    func sendData(data: String){
//        if session.connectedPeers.count > 0{
//            if let data = data.data(using:.utf8){
//                do{
//                    try session.send(data,toPeers: session.connectedPeers, with: .reliable)
//                }catch let error as NSError{
//                    print(error.localizedDescription)
//                }
//            }
//        }
//    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Player", for: indexPath)
    
        if !self.connectedPeers.isEmpty && indexPath.row <
            self.connectedPeers.count{
            //print("1: All conntected peers: \(self.connectedPeers)")
            print("1: adding \(self.connectedPeers[indexPath.row]) to row: \(indexPath.row)")
            cell.textLabel?.text = self.connectedPeers[indexPath.row]
//            print("========TableView adding========")
//            for i in self.connectedPeers{
//                print(i)
//            }
        }else{
            cell.textLabel!.text = "Waiting..."
        }
            
        return cell
    }
    
    func startHosting(){
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "quiz")
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }
    func joinSession(){
        browser = MCBrowserViewController(serviceType: "quiz", session: session)
        browser.delegate = self
        if advertiser != nil{
            advertiser.stopAdvertisingPeer()
        }
        present(browser, animated: true)
    }
    func initializeSession(name: String){
        peer = MCPeerID(displayName: name)
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
    }
    // MARK: - MCNearbyServiceAdvertiserDelegate
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
        
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let alertController = UIAlertController(title: "'\(peerID.displayName)' wants to connect", message: nil, preferredStyle: .alert)
               alertController.addAction(UIAlertAction(title: "Accept", style: .default, handler: { [weak self] _ in
                   invitationHandler(true, self?.session)
               }))
               alertController.addAction(UIAlertAction(title: "Decline", style: .cancel, handler: { _ in
                   invitationHandler(false, nil)
               }))
               present(alertController, animated: true)
        
    }
    
    //Not needed for MCBrowserDelagate, dont need
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        ///print(error.localizedDescription)
    }
    // MARK: - MCBrowserViewController, dont need
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    // MARK: - MCSessionDelegate
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async(execute:{ [unowned self] in
            print("===========\(data)")
            if (try? JSONDecoder().decode(Bool.self, from: data)) != nil{
                print("sending bool worked")
                performSegue(withIdentifier: "start-quiz", sender: self)
                
            }
            if (try? JSONDecoder().decode(String.self, from: data)) != nil{
                
                if !self.connectedPeers.contains(where: {$0 == peerID.displayName}){
                    self.connectedPeers.append(peerID.displayName)
                    self.joinedPlayers.reloadData()
                    
                }
            }
        })
        
        
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async(execute: { [self] in
            switch state{
            case MCSessionState.connected:
                print("1: Connected: \(peerID.displayName)")
             
                self.dismiss(animated: true)
                
                if !connectedPeers.contains(where: { $0 == peerID.displayName})
                {
                    print("1: adding \(peerID)")
                    
                    do{
                        try session.send(JSONEncoder().encode("connected"), toPeers: session.connectedPeers, with: .reliable)
                       
                    }catch _ as NSError{
                        //print(error.localizedDescription)
                    }

                }
                
                
            case MCSessionState.connecting:
                print("Connecting: \(peerID.displayName)")
                
            case MCSessionState.notConnected:
                print("Not Connected: \(peerID.displayName)")
                DispatchQueue.main.async {
                    if let playerIndex = (self.connectedPeers.firstIndex { $0 == peerID.displayName}){
                        self.connectedPeers.remove(at: playerIndex)
                    }
                    self.joinedPlayers.reloadData()
                    
                    
                }
            @unknown default:
                fatalError()
            }
        })
//        DispatchQueue.main.async {
//            do{
//                try session.send(JSONEncoder().encode(self.player), toPeers: session.connectedPeers, with: .reliable)
//                print("player pic sent")
//            }catch{}
//        }
        
    }
    
    static func  saveData(data: Player){
        let encodedData = try! JSONEncoder().encode(data)
        UserDefaults.standard.set(encodedData, forKey:"user-info")
    }
    static func getData()->Player?{
        if UserDefaults.standard.data(forKey: "user-info") != nil{
            let data = UserDefaults.standard.data(forKey: "user-info")
            let decodedData = try! JSONDecoder().decode(Player.self, from: data!)
            return decodedData
        }
        return nil
    }
   
    

}

