import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventide_app/models/conversation_model.dart';
import 'package:eventide_app/models/organizer_model.dart';
import 'package:eventide_app/models/user_model.dart';
import 'package:logger/logger.dart';

class ChatController {
  // Create a CollectionReference called users that references the firestore collection
  CollectionReference conversations =
      FirebaseFirestore.instance.collection('conversations');

  //----save extra user data in firestore
  Future<ConversationModel> createConersation(
      UserModel me, OrganizerModel peeruser) async {
    //-check conversation exists
    ConversationModel? model = await checkConvExist(me.uid, peeruser.uid);

    if (model == null) {
      String docId = conversations.doc().id;

      await conversations
          .doc(docId)
          .set(
            {
              'id': docId,
              'users': [me.uid, peeruser.uid],
              'usersArray': [me.toJson(), peeruser.toJson()],
              'lastMessage': "started the conversation",
              'lastMessageTime': DateTime.now().toString(),
              'createdBy': me.uid,
              'createdAt': DateTime.now().toString(),
            },
          )
          .then((value) => Logger().i("Conversation added"))
          .catchError((error) => Logger().e("Failed to merge data: $error"));

      DocumentSnapshot snapshot = await conversations.doc(docId).get();
      return ConversationModel.fromJason(
          snapshot.data() as Map<String, dynamic>);
    } else {
      return model;
    }
  }

  Future<ConversationModel?> checkConvExist(String myId, String peerId) async {
    try {
      ConversationModel? conModel;
      QuerySnapshot result = await conversations
          .where('users', arrayContainsAny: [myId, peerId]).get();

      for (var e in result.docs) {
        var model =
            ConversationModel.fromJason(e.data() as Map<String, dynamic>);

        if (model.users.contains(myId) && model.users.contains(peerId)) {
          Logger().w("the conversation is already exists");
          conModel = model;
        } else {
          Logger().w("the conversation is not exists");
          conModel = null;
        }
      }
      return conModel;
    } catch (e) {
      Logger().e(e);
      return null;
    }
  }

  //----------retreive conversation stream
  Stream<QuerySnapshot> getConversations(String currentUserId) => conversations
      .orderBy('createdAt', descending: true)
      .where('users', arrayContainsAny: [currentUserId]).snapshots();

  //-message sent fuction
  CollectionReference messages =
      FirebaseFirestore.instance.collection('messages');

  Future<void> sendMessage(
    String conId,
    String senderName,
    String senderId,
    String reciveId,
    String message,
  ) async {
    try {
      await messages.add({
        "conId": conId,
        "senderName": senderName,
        "senderId": senderId,
        "reciveId": reciveId,
        "message": message,
        "messageTime": DateTime.now().toString(),
        "createdAt": DateTime.now(),
      });
      //----update the conversation lastmesage
      await conversations.doc(conId).update({
        'lastMessage': message,
        'lastMessageTime': DateTime.now().toString(),
        'createdAt': DateTime.now()
      });
    } catch (e) {
      Logger().e(e);
    }
  }

  //----------retreive message stream
  Stream<QuerySnapshot> getMessages(String conId) => messages
      .orderBy('createdAt', descending: true)
      .where('conId', isEqualTo: conId)
      .snapshots();
}
