import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import 'login_screen.dart';
final _fireStore = FirebaseFirestore.instance;
late User loggedInUser;
class ChatScreen extends StatefulWidget {
  static String id='chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final dateTime;
  final messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late String message;

  void getCurrentUser() async{
    try{
      final user = await _auth.currentUser;
      if(user != null){
        loggedInUser  = user;
        print(loggedInUser.email);
      }
    }catch(e){
      print(e);
    }
  }
  // void getMessages() async{
  //   final messages = await _fireStore.collection('messages').get();
  //   for(var message in messages.docs){
  //     print(message.data()['text']);
  //   }
  // }
  void messagesStream() async{
    await for (var snapshot in _fireStore.collection('messages')
        .snapshots()){
      for(var message in snapshot.docs){
        print(message.data()['text']);
      }
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
    dateTime = DateTime.now();
    print(dateTime);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                messagesStream();
                _auth.signOut();
                Navigator.pushNamed(context, LoginScreen.id);
                //Implement logout functionality
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      style: TextStyle(
                        color: Color(0xff414141)
                      ),
                      onChanged: (value) {
                        message = value;
                        //Do something with the user input.
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageController.clear();
                      _fireStore.collection('messages').add(
                      {
                        'text': message,
                        'sender' : loggedInUser.email,
                        'timeStamp':
                        DateTime.now().toUtc().microsecondsSinceEpoch,
                      },
                      );
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}class MessageStream extends StatelessWidget {
  const MessageStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder <QuerySnapshot>(
      stream: _fireStore.collection('messages').
      orderBy('timestamp', descending: true).snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        if(snapshot.hasData){
          final messages = snapshot.data.docs;
          List<MessageBubble> messageBubbles= [];
          for(var message in messages){
            final messageText = message.data()['text'];
            final messageSender = message.data()['sender'];
            // final messageTime = message.data()['timeStamp'];
            final currentUser =loggedInUser.email;
            if(currentUser == messageSender){
              //the message is from logged in user
            }
            final messageBubble=   MessageBubble(
              text: messageText,
              sender: messageSender,
              // time: messageTime.toString(),
              isMe: currentUser == messageSender,
            );
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),

              children: messageBubbles,
            ),
          );

        }else{
          return Center(
            heightFactor: 10,
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlue,
              strokeWidth: 3.0,
            ),
          );
        }
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.text, required this.sender, required this.isMe});
  final String text;
  final String sender;
  final bool isMe;
  // final String time;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe?
        CrossAxisAlignment.end: CrossAxisAlignment.start,
        children: [
          Text(sender,
            style: TextStyle(
                fontSize: 12,
                color:Colors.black38
            ),),
          SizedBox(
            height: 8,
          ),
          Material(
            elevation: 5.0,
            borderRadius: isMe?
            BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))
                :BorderRadius.only(topRight: Radius.circular(30), bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            color: isMe== true? Colors.lightBlueAccent: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black38
                ),
              ),
            ),
          ),
          // Text(time),
          SizedBox(
            height: 8,
          ),
          // Text(time,
          //   style: TextStyle(
          //       fontSize: 12,
          //       color:Colors.black38
          //   ),)
        ],
      ),
    );
  }
}

