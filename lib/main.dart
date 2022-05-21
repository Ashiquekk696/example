import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twilio_conversations/api.dart';
import 'package:twilio_conversations/twilio_conversations.dart';
import 'package:twilio_conversations_example/conversations/conversations_notifier.dart';
import 'package:twilio_conversations_example/conversations/conversations_page.dart';
import 'package:twilio_conversations_example/messages/messages_page.dart';
import 'package:twilio_conversations_example/messages/messages_page2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twilio_conversations_example/voicerecrdg.dart';

void main() async {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (_) => ConversationsNotifier(),
    )
  ], child: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  start() async {
    var notifier = Provider.of<ConversationsNotifier>(context, listen: false);
    await notifier.startClient();
    await ConversationsNotifier().getMyConversations();
  }

  late Conversation conversation =
      Conversation("CH2b1e3855288345689c02af617b92609b");

  @override
  void initState() {
    start();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:
          //Mmm()
          Scaffold(
        appBar: AppBar(
          title: const Text('Twilio Conversations Example'),
        ),
        body: Center(
          child: Column(
            children: [
              // _buildUserIdField(),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget randomChat(Conversation conversation) {
  //   return GestureDetector(
  //     child: Container(
  //       color: Colors.red,
  //       child: Text('Conversation: ${conversation.friendlyName}'),
  //     ),
  //     onTap: () {
  //       // print(widget.conversationsNotifier.client);
  //       Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //               builder: (context) => MessagesPage(
  //                   conversation, widget.conversationsNotifier.client!)));
  //     },
  //   );
  // }
  Widget _buildButtons() {
    return Consumer<ConversationsNotifier>(
      builder: (BuildContext context, conversationsNotifier, Widget? child) {
        print(conversationsNotifier.isClientInitialized);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // MessagesPage(Conversation("CHf9c8b5aeea4941c4ab01f47ae096c33a"),
            //     conversationsNotifier.client!),
            TextFormField(
              controller: conversationsNotifier.identityController,
              onChanged: conversationsNotifier.updateIdentity,
            ),
            // ElevatedButton(
            //   onPressed: conversationsNotifier.identity.isNotEmpty &&
            //           !conversationsNotifier.isClientInitialized
            //       ? () async {
            //           // <Set your JWT token here>
            //           String? jwtToken = await getToken();
            //
            //           if (jwtToken == null) {
            //             return;
            //           }
            //
            //           if (jwtToken.isEmpty) {
            //             _showInvalidJWTDialog(context);
            //             return;
            //           }
            //           await conversationsNotifier.create(jwtToken: jwtToken);
            //         }
            //       : null,
            //   child: Text('Start Client'),
            // ),
            // ElevatedButton(
            //   onPressed: conversationsNotifier.isClientInitialized
            //       ? () async {
            //           String? jwtToken;
            //
            //           if (jwtToken == null) {
            //             return;
            //           }
            //
            //           if (jwtToken.isEmpty) {
            //             _showInvalidJWTDialog(context);
            //             return;
            //           }
            //           await conversationsNotifier.updateToken(
            //               jwtToken: jwtToken);
            //         }
            //       : null,
            //   child: Text('Update Token'),
            // ),
            // ElevatedButton(
            //   onPressed: conversationsNotifier.isClientInitialized
            //       ? () async {
            //           await conversationsNotifier.shutdown();
            //         }
            //       : null,
            //   child: Text('Shutdown Client'),
            // ),

            // ElevatedButton(
            //   onPressed: conversationsNotifier.isClientInitialized
            //       ? () => conversationsNotifier.join(
            //           sid: "CHf9c8b5aeea4941c4ab01f47ae096c33a")
            //       : null,
            //   child: Text('join Conversations'),
            // ),

            ElevatedButton(
              onPressed: conversationsNotifier.isClientInitialized
                  ? () {
                      print(conversationsNotifier.friendlyName);
                      conversationsNotifier.getMyConversations();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MessagesPage2(
                                  Conversation(
                                      "CHf9c8b5aeea4941c4ab01f47ae096c33a"),
                                  //conversationsNotifier.conversations[0],
                                  conversationsNotifier,
                                )
                            // ConversationsPage(
                            //     conversationsNotifier: conversationsNotifier),
                            ),
                      );

                      // print(
                      //     conversationsNotifier.conversations[0].friendlyName);
                    }
                  : null,
              child: Text('Join Conversation'),
            ),
            // randomChat(
            //     //conversationsNotifier.conversations[0] ??
            //     Conversation("CHf9c8b5aeea4941c4ab01f47ae096c33a"),
            //     conversationsNotifier.client!)
          ],
        );
      },
    );
  }

  // Widget randomChat(
  //     Conversation conversation, ConversationClient conversationClient) {
  //   return GestureDetector(
  //     child: Container(
  //       color: Colors.red,
  //       child: Text('Conversation: ${conversation.friendlyName}'),
  //     ),
  //     onTap: () {
  //       // print(widget.conversationsNotifier.client);
  //       Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //               builder: (context) =>
  //                   MessagesPage(conversation, conversationClient)));
  //     },
  //   );
  // }

  void _showInvalidJWTDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error: No JWT provided'),
        content: Text(
            'To create the conversations client, a JWT must be supplied on line 44 of `main.dart`'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
