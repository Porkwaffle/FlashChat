//
//  ViewController.swift
//  Flash Chat

import UIKit
import Firebase
import SVProgressHUD
import ChameleonFramework

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    //Instance variables
    var messageArray : [Message] = [Message]()
    
    //IBOutlets
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var messageTextfield: UITextField!
    @IBOutlet var messageTableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set yourself as the delegate and datasource
        messageTableView.delegate = self
        messageTableView.dataSource = self
        
        //Set yourself as the delegate of the text field
        messageTextfield.delegate = self
        
        
        //Set the tapGesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        messageTableView.addGestureRecognizer(tapGesture)
        

        //Register MessageCell.xib file
        messageTableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")
        
        //Make cells as large as the content inside
        configureTableView()
        
        //Grab messages
        retrieveMessages()
        
        messageTableView.separatorStyle = .none
        
    }

    ///////////////////////////////////////////
    
    //MARK: - TableView DataSource Methods
    
    
    //Declare cellForRowAtIndexPath
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
        
        cell.messageBody.text = messageArray[indexPath.row].messageBody
        cell.senderUsername.text = messageArray[indexPath.row].sender
        cell.avatarImageView.image = UIImage(named: "egg")
        
        //Change colors based on who is sending the message
        if cell.senderUsername.text == Auth.auth().currentUser?.email as String! {
            //Messages we sent
            cell.avatarImageView.backgroundColor = UIColor.flatMint()
            cell.messageBackground.backgroundColor = UIColor.flatSkyBlue()
        } else {
            cell.avatarImageView.backgroundColor = UIColor.flatWatermelon()
            cell.messageBackground.backgroundColor = UIColor.flatGray()
        }
        
        return cell
    }
    
    
    //numberOfRowsInSection
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArray.count
    }
    
    
    //tableViewTapped
    @objc func tableViewTapped() {
        messageTextfield.endEditing(true)
    }
    
    
    //configureTableView
    func configureTableView() {
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTableView.estimatedRowHeight = 120.0
    }
    
    
    ///////////////////////////////////////////
    
    //MARK:- TextField Delegate Methods
    
    //textFieldDidBeginEditing
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.5) {
            self.heightConstraint.constant = 308
            
            //Redraw view if something has changed
            self.view.layoutIfNeeded()
        }
    }
    
    
    //textFieldDidEndEditing - Must call manually
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.5) {
            self.heightConstraint.constant = 50
            self.view.layoutIfNeeded()
        }
    }

    
    ///////////////////////////////////////////
    
    //MARK: - Send & Recieve from Firebase
    
    @IBAction func sendPressed(_ sender: AnyObject) {
        
        messageTextfield.endEditing(true)
        messageTextfield.isEnabled = false
        sendButton.isEnabled = false
        
        //Send the message to Firebase and save it in our database
        let messagesDB = Database.database().reference().child("Messages")
        let messageDictionary = ["Sender": Auth.auth().currentUser?.email, "MessageBody": messageTextfield.text]
        
        //Save message dictionary inside message database under a unique ID
        messagesDB.childByAutoId().setValue(messageDictionary) {
            (error, reference) in
            
            if error != nil {
                print(error)
            } else {
                print("Message saved successfully")
                self.messageTextfield.isEnabled = true
                self.sendButton.isEnabled = true
                self.messageTextfield.text = ""
            }
        }
    }
    
    //retrieveMessages
    func retrieveMessages() {
        let messageDB = Database.database().reference().child("Messages")
        
        //Grab new messages as they come into database
        messageDB.observe(.childAdded) { (snapshot) in
            let snapshotValue = snapshot.value as! Dictionary<String, String>
            
            let text = snapshotValue["MessageBody"]!
            let sender = snapshotValue["Sender"]!
            
            let message = Message()
            message.messageBody = text
            message.sender = sender
            
            //Add message object to array
            self.messageArray.append(message)
            
            self.configureTableView()
            self.messageTableView.reloadData()
        }
    }
    
    
    
    @IBAction func logOutPressed(_ sender: AnyObject) {
        
        //Log out the user and send them back to WelcomeViewController
        do {
            try Auth.auth().signOut()
            
            navigationController?.popToRootViewController(animated: true)
        }
        catch {
            print("Error, there was a problem signing out.")
        }
    }
    


}
