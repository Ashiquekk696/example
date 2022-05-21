import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:twilio_conversations/twilio_conversations.dart';

class ConversationsNotifier extends ChangeNotifier {
  final plugin = TwilioConversations();
  ConversationClient? client;
  bool isClientInitialized = false;
  TextEditingController identityController = TextEditingController();
  String identity = '';
  String? friendlyName;

  List<Conversation> conversations = [];
  Map<String, int> unreadMessageCounts = {};

  final subscriptions = <StreamSubscription>[];

  void updateIdentity(String identity) {
    this.identity = identity;
    notifyListeners();
  }

  Future getToken() async {
    var headers = {
      'Authorization':
          'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOlwvXC9lYzItMy0xMDgtMTc1LTguYXAtc291dGgtMS5jb21wdXRlLmFtYXpvbmF3cy5jb21cL2FiYVwvYXBwXC91c2VyXC9sb2dpbiIsImlhdCI6MTY1Mjg0OTI3OCwiZXhwIjoxNjU2NDQ5Mjc4LCJuYmYiOjE2NTI4NDkyNzgsImp0aSI6InpVcWZNRXVDOVR6VVNsYksiLCJzdWIiOjcsInBydiI6IjIzYmQ1Yzg5NDlmNjAwYWRiMzllNzAxYzQwMDg3MmRiN2E1OTc2ZjciLCJuYW1lIjoiQmhhcnRoaUthbm5hbiIsImlkIjo3LCJyb2xlIjoidXNlciJ9.yv_MDYcMpqeC8dHkh7k584wGkAv41E8KxLvtgkIctrY'
    };
    var url =
        'http://ec2-3-108-175-8.ap-south-1.compute.amazonaws.com/aba/app/user/new_conversation';
    var response = await http.get(Uri.parse(url), headers: headers);
    var data = jsonDecode(response.body);
    print("${data['user_access_token']}kkk");
    print(data['message']);
    return data['user_access_token'];
  }

  startClient() async {
    var jwtToken = await getToken();
    // "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTS2Y3OGE2OWMzNjVjZThiYWI0YThkYWRlZWRjNDAxODlkLTE2NTIwOTU1MDkiLCJpc3MiOiJTS2Y3OGE2OWMzNjVjZThiYWI0YThkYWRlZWRjNDAxODlkIiwic3ViIjoiQUMxN2ZjMDhmYWY2NGY5M2M0MWRmODE0MzQ2NDcyMWFiMCIsImV4cCI6MTY1MjA5OTEwOSwiZ3JhbnRzIjp7ImlkZW50aXR5IjoibWFpbHM0cmJrQGdtYWlsLmNvbSIsImNoYXQiOnsic2VydmljZV9zaWQiOiJJUzgyZjRiNjM3ZGZiYTRiOTA4MGQ1NmVhMTc0YjFiOTY1In19fQ.UEQjbyQs2mW44eutRxxtA5RHgcOJDgejpu1NL5cKXhk";
    await create(jwtToken: jwtToken);
    // "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTS2Y3OGE2OWMzNjVjZThiYWI0YThkYWRlZWRjNDAxODlkLTE2NTE5MTQwMTEiLCJpc3MiOiJTS2Y3OGE2OWMzNjVjZThiYWI0YThkYWRlZWRjNDAxODlkIiwic3ViIjoiQUMxN2ZjMDhmYWY2NGY5M2M0MWRmODE0MzQ2NDcyMWFiMCIsImV4cCI6MTY1MTkxNzYxMSwiZ3JhbnRzIjp7ImlkZW50aXR5IjoibWFpbHM0cmJrQGdtYWlsLmNvbSIsImNoYXQiOnsic2VydmljZV9zaWQiOiJJUzgyZjRiNjM3ZGZiYTRiOTA4MGQ1NmVhMTc0YjFiOTY1In19fQ.tZV1cM_xWbgYba-fdFAD-RioZcYnlx6jX4zYGgFlD_8");
  }

  Future<void> create({required String jwtToken}) async {
    updateIdentity('Meera');
    await TwilioConversations.debug(dart: true, native: true, sdk: false);

    print('debug logging set, creating client...');
    client = await plugin.create(jwtToken: jwtToken);

    print('Client initialized');
    print('Your Identity: ${client?.myIdentity}');

    final uClient = client;
    if (uClient != null) {
      isClientInitialized = true;
      await updateFriendlyName();
      notifyListeners();

      subscriptions.add(uClient.onConversationAdded.listen((event) {
        getMyConversations();
      }));

      subscriptions.add(uClient.onConversationUpdated.listen((event) {
        getMyConversations();
      }));

      subscriptions.add(uClient.onConversationDeleted.listen((event) {
        getMyConversations();
      }));
    }
  }

  Future<void> updateToken({required String jwtToken}) async {
    await client?.updateToken(jwtToken);
    return;
  }

  Future<void> shutdown() async {
    final client = TwilioConversations.conversationClient;
    if (client != null) {
      await client.shutdown();
      isClientInitialized = false;
      notifyListeners();
    }
  }

  Future<void> markRead(Conversation conversation) async {
    await conversation.setAllMessagesRead();
    notifyListeners();
  }

  Future<void> markUnread(Conversation conversation) async {
    await conversation.setAllMessagesUnread();
    notifyListeners();
  }

  Future<void> join({sid}) async {
    await Conversation.join(sid: sid);
    notifyListeners();
  }

  Future<void> leave(Conversation conversation) async {
    await conversation.leave();
    notifyListeners();
  }

  Future<void> setFriendlyName(String friendlyName) async {
    final myUser = await TwilioConversations.conversationClient?.getMyUser();
    await myUser?.setFriendlyName(friendlyName);
    await updateFriendlyName();
    notifyListeners();
  }

  Future<void> updateFriendlyName() async {
    final myUser = await TwilioConversations.conversationClient?.getMyUser();
    friendlyName = myUser?.friendlyName;
  }

  Future<Conversation?> createConversation(
      {String friendlyName = 'Test Conversation'}) async {
    var result = await TwilioConversations.conversationClient
        ?.createConversation(friendlyName: friendlyName);
    print('Conversation successfully created: ${result?.friendlyName}');
    return result;
  }

  Future<void> getMyConversations() async {
    final myConversations =
        await TwilioConversations.conversationClient?.getMyConversations();

    if (myConversations != null) {
      conversations = myConversations;
      await Future.forEach(conversations, (Conversation conversation) async {
        late int unreadMessages;
        try {
          unreadMessages = await conversation.getUnreadMessagesCount();
        } on PlatformException {
          unreadMessages = 0;
        }

        if (unreadMessages == 0) {
          // If unreadMessages comes back as `null` it means that
          // no last read message index has been set, so unread messages
          // will continue to report null until this has been done.
          final messagesCount = await conversation.getMessagesCount();
          if (messagesCount != null && messagesCount > 0) {
            await conversation.setLastReadMessageIndex(0);
          }
          var totalMessages = await conversation.getMessagesCount();
          unreadMessageCounts[conversation.sid] = totalMessages ?? 0;
        } else {
          unreadMessageCounts[conversation.sid] = unreadMessages;
        }
      });
      notifyListeners();
    }
  }

  Future<void> registerForNotification() async {
    String? token;
    if (Platform.isAndroid) {
      token = await FirebaseMessaging.instance.getToken();
    }
    await client?.registerForNotification(token);
  }

  Future<void> unregisterForNotification() async {
    String? token;
    if (Platform.isAndroid) {
      token = await FirebaseMessaging.instance.getToken();
    }
    await client?.unregisterForNotification(token);
  }

  void cancelSubscriptions() {
    for (var sub in subscriptions) {
      sub.cancel();
    }
  }
}
