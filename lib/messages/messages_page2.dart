import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twilio_conversations/twilio_conversations.dart';
import 'package:twilio_conversations_example/conversations/conversations_notifier.dart';
import 'package:twilio_conversations_example/messages/messages_notifier.dart';
import 'package:twilio_conversations_example/messages/pdf_page.dart';
import 'package:twilio_conversations_example/util.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:twilio_conversations_example/widgets/voice_slider.dart';
import '../conversations/conversations_notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_document/open_document.dart';
import 'package:lottie/lottie.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class MessagesPage2 extends StatefulWidget {
  final Conversation conversation;

  // final ConversationClient client;
  final ConversationsNotifier conversationNotifier;

  MessagesPage2(this.conversation, this.conversationNotifier);

  @override
  _MessagesPage2State createState() => _MessagesPage2State();
}

class _MessagesPage2State extends State<MessagesPage2>
    with SingleTickerProviderStateMixin {
  late final MessagesNotifier messagesNotifier;

  late final ConversationsNotifier conversationNotifier;
  Conversation? convrstns;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool voiceIsRecording = false;
  AnimationController? voiceRecdController;
  bool? micActive = false;

  @override
  void initState() {
    getData();

    setState(() {});
    super.initState();
  }

  getData() async {
    final myConversations = await TwilioConversations.conversationClient
        ?.getConversation("CH2b1e3855288345689c02af617b92609b");
    print("myConversations?.sid");

    convrstns = myConversations;
    setState(() {
      messagesNotifier =
          MessagesNotifier(convrstns!, widget.conversationNotifier.client!);
      print("notifier");
      print(messagesNotifier.messages.length);
      print("notifier");
      messagesNotifier.loadConversation();
      messagesNotifier.loadMessages();
    });

    print("messages?.length");
    print(messagesNotifier.messages.length);

    print("messages?.length");
  }

  @override
  void dispose() {
    voiceRecdController?.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  var selectedFile;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MessagesNotifier>.value(
      value: messagesNotifier,
      child: Consumer<MessagesNotifier>(
        builder: (BuildContext context, messagesNotifier, Widget? child) {
          print("${messagesNotifier.voiceSlidePosition}jas");
          return WillPopScope(
            onWillPop: () async {
              messagesNotifier.cancelSubscriptions();
              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                title: InkWell(
                    onLongPress: _updateFriendlyName,
                    onDoubleTap: _updateUniqueName,
                    // child: Text(widget.conversation.friendlyName ?? '')),

                    child: Text(convrstns?.friendlyName ?? '')),
                actions: [
                  _buildOverflowButton(),
                ],
              ),
              body: Center(
                // convrstns.message
                child:
                    // messagesNotifier.isLoading?
                    // Center(child: CircularProgressIndicator(),):
                    _buildBody(messagesNotifier),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverflowButton() {
    return PopupMenuButton(
      icon: Icon(Icons.menu),
      onSelected: (result) {
        switch (result) {
          case MessagesPageMenuOptions.participants:
            _showManageParticipantsDialog();
            break;
          case MessagesPageMenuOptions.destroyConversation:
            _destroyConversation();
            break;
          case MessagesPageMenuOptions.swapAttributes:
            _showSwapAttributesDialog();
            break;
          case MessagesPageMenuOptions.myAttributes:
            _showMyAttributesDialog();
            break;
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<MessagesPageMenuOptions>>[
        PopupMenuItem(
          value: MessagesPageMenuOptions.participants,
          child: Text('Participants'),
        ),
        PopupMenuItem(
          value: MessagesPageMenuOptions.destroyConversation,
          child: Text('Destroy Conversation'),
        ),
        PopupMenuItem(
          value: MessagesPageMenuOptions.swapAttributes,
          child: Text('Conversation Attributes'),
        ),
        PopupMenuItem(
          value: MessagesPageMenuOptions.myAttributes,
          child: Text('My Attributes'),
        ),
        PopupMenuItem(
            value: MessagesPageMenuOptions.clearChat, child: Text("Clear Chat"))
      ],
    );
  }

  Widget _buildBody(MessagesNotifier messagesNotifier) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
              child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              color: Colors.grey[100],
              child: _buildListStates(messagesNotifier),
            ),
          )),
          _buildParticipantsTyping(messagesNotifier),
          _buildMessageInputBar(messagesNotifier),
        ],
      ),
    );
  }

  Widget _buildListStates(MessagesNotifier messagesNotifier) {
    if (messagesNotifier.isLoading && messagesNotifier.messages.isEmpty) {
      return Center(child: Container());
    }

    if (messagesNotifier.isError) {
      return Center(
        child: IconButton(
          icon: Icon(Icons.replay),
          onPressed: () {
            messagesNotifier.refetchAfterError();
          },
        ),
      );
    }

    if (messagesNotifier.messages.isEmpty) {
      return Center(
        child: Icon(
          Icons.speaker_notes_off,
          size: 48,
        ),
      );
    }

    return _buildList(messagesNotifier);
  }

  Widget _buildList(MessagesNotifier messagesNotifier) {
    var listCount = messagesNotifier.messages.length;
    print(messagesNotifier.messages);

    if (messagesNotifier.isLoading) {
      //Increment list count by 1
      // so that loading spinner can be shown above existing messages
      // when retrieving the next page
      listCount += 1;
    }
    return ListView.builder(
      controller: messagesNotifier.listScrollController,
      reverse: true,
      itemCount: listCount,
      itemBuilder: (_, index) {
        if (listCount == messagesNotifier.messages.length + 1 &&
            index == listCount - 1) {
          return Center(child: Container());
        }
        return _buildListItem(messagesNotifier.messages[index]);
      },
    );
  }

  Widget _buildListItem(Message message) {
    final isMyMessage =
        message.author == TwilioConversations.conversationClient?.myIdentity;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment:
            isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildChatBubble(message),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Message message) {
    final isMyMessage =
        message.author == TwilioConversations.conversationClient?.myIdentity;

    final textColor = isMyMessage ? Colors.white : Colors.black;

    return GestureDetector(
      onDoubleTap: () async {
        final messagesBefore = await messagesNotifier.conversation
            .getMessagesBefore(index: message.messageIndex!, count: 3);
        final messagesAfter = await messagesNotifier.conversation
            .getMessagesAfter(index: message.messageIndex!, count: 3);
        final messageByIndex = await messagesNotifier.conversation
            .getMessageByIndex(message.messageIndex!);
        final participant = await message.getParticipant();
        print(
            'message: ${messageByIndex.messageIndex}\n\tsentBy: ${participant?.sid}\n\tmessagesBefore: ${messagesBefore.length}\n\tmessagesAfter: ${messagesAfter.length}');
      },
      onLongPressEnd: (LongPressEndDetails details) =>
          _showMessageOptionsMenu(message, details.globalPosition),
      child: Column(
        crossAxisAlignment:
            isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 4.0),
            constraints: BoxConstraints(maxWidth: 250, minHeight: 35),
            decoration: BoxDecoration(
                color: isMyMessage ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.circular(8.0)),
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 4),
              child: Column(
                crossAxisAlignment: isMyMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildAuthorName(
                    message: message,
                    isMyMessage: isMyMessage,
                    textColor: textColor,
                  ),
                  _buildMessageContents(
                    message: message,
                    textColor: textColor,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            message.dateCreated != null
                ? ConversationsUtil.parseDateTime(message.dateCreated!)
                : '',
            textAlign: isMyMessage ? TextAlign.start : TextAlign.end,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w300,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorName({
    required bool isMyMessage,
    required Color textColor,
    required Message message,
  }) {
    // TODO: revisit logic, seems wonky
    return (isMyMessage)
        ? Container(
            width: 0,
          )
        : Column(
            crossAxisAlignment:
                isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                (!isMyMessage) ? message.author! : '',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
            ],
          );
  }

  Widget _buildMessageContents({
    required Color textColor,
    required Message message,
  }) {
    if (message.type == MessageType.TEXT) {
      return Text(
        message.body ?? '',
        style: TextStyle(
          color: textColor,
          fontSize: 13,
        ),
      );
    } else if (message.sid != null && messagesNotifier.hasMedia(message.sid!)) {
      print("messagesNotifier.media(message.sid!)");
      print(message.media?.type);
      print("messagesNotifier.media(message.sid!)");

      switch (message.media!.type) {
        case "image/jpeg":
          return GestureDetector(
            onTap: () {
              fileCreate(messagesNotifier.media(message.sid!));
              print("${message.media?.fileName}jabirr");
              OpenFile.open(file?.path);
            },
            child: Center(
                child: Image.memory(messagesNotifier.media(message.sid!)!)),
          );

        case "image/png":
          return GestureDetector(
            onTap: () {
              fileCreate(messagesNotifier.media(message.sid!));

              OpenFile.open(file?.path);
            },
            child: Center(
                child: Image.memory(messagesNotifier.media(message.sid!)!)),
          );
        case "application/pdf":
          return Center(
              child: GestureDetector(
            onTap: () {
              print("sddd${message.media?.fileName}");
              // showDialog(
              //     context: context,
              //     builder: (context) {
              //       return Dialog(
              //           child: Container(
              //         height: 480,
              //         child: SfPdfViewer.memory(
              //             messagesNotifier.media(message.sid!)!),
              //       ));
              //     });

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PdfReaderPage(
                            filePath: messagesNotifier.media(
                              message.sid!,
                            ),
                            fileName: message.media?.fileName,
                          )));
            },
            child: Container(
                color: Colors.white,
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 40,
                    ),
                    Text(
                      message.media?.fileName ?? "",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    )
                  ],
                )),
          ));

        case "application/msword":
          return Center(
              child: GestureDetector(
            onTap: () async {
              print("hh${message.media?.type}");
              await fileCreate(messagesNotifier.media(message.sid!),
                  fileName: message.media?.fileName);
              OpenFile.open(file?.path, type: "application/msword");
            },
            child: Container(
                color: Colors.white,
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_copy,
                      color: Colors.blue,
                      size: 40,
                    ),
                    Text(
                      message.media?.fileName ?? "",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    )
                  ],
                )),
          ));

        case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
          return Center(
              child: GestureDetector(
            onTap: () async {
              print("hh${message.media?.type}");
              await fileCreate(messagesNotifier.media(message.sid!),
                  fileName: message.media?.fileName);
              OpenFile.open(file?.path,
                  type:
                      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            },
            child: Container(
                color: Colors.white,
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_copy,
                      color: Colors.green,
                      size: 40,
                    ),
                    Text(
                      message.media?.fileName ?? "",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    )
                  ],
                )),
          ));

        case "application/zip":
          return Center(
              child: GestureDetector(
            onTap: () async {
              print("hh${message.media?.type}");
              await fileCreate(messagesNotifier.media(message.sid!),
                  fileName: message.media?.fileName);
              OpenFile.open(file?.path, type: "application/zip");
            },
            child: Container(
                color: Colors.white,
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_zip,
                      color: Colors.orangeAccent.withOpacity(0.8),
                      size: 40,
                    ),
                    Text(
                      message.media?.fileName ?? "",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    )
                  ],
                )),
          ));

        case "video/mp4":
          return Center(
              child: GestureDetector(
            onTap: () async {
              print("hh${message.media?.type}");
              await fileCreate(messagesNotifier.media(message.sid!),
                  fileName: message.media?.fileName);
              OpenFile.open(file?.path, type: "video/mp4");
            },
            child: Container(
                color: Colors.white,
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_collection,
                      color: Colors.orangeAccent.withOpacity(0.8),
                      size: 40,
                    ),
                    Text(
                      "" ?? "",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    )
                  ],
                )),
          ));

        case "audio/x-aac":
          return VoiceSlider(
            // pis: (messagesNotifier.voiceSlidePosition),
            // dis: (messagesNotifier.voiceSlideDuration),
            notifier: messagesNotifier,
            message: message,
          );

        //     Container(
        //   height: 50,
        //   color: Colors.white,
        //   child: Row(
        //     children: [
        //       _voicePlayButton(messagesNotifier.media(message.sid!),
        //           message.media?.fileName),
        //       Container(
        //         height: 15,
        //         child: Slider(
        //           value: messagesNotifier.voiceSlidePosition ?? 0.0,
        //           min: 0,
        //           max: messagesNotifier.voiceSlideDuration,
        //           onChanged: (value) async {
        //             messagesNotifier.voiceSlidePosition = value;
        //             await messagesNotifier.myPlayer?.seekToPlayer(
        //                 Duration(milliseconds: (value / 1000).toInt()));
        //             setState(() {});
        //           },
        //         ),
        //       )
        //     ],
        //   ),
        // );

        //     Container(
        //   height: 50,
        //   color: Colors.white,
        //   child: Row(
        //     children: [
        //       _voicePlayButton(messagesNotifier.media(message.sid!),
        //           message.media?.fileName),
        //       Container(
        //           height: 15,
        //           width: 111,
        //           child: ProgressBar(
        //               progress: Duration(
        //                   milliseconds:
        //                       (messagesNotifier.voiceSlidePosition).toInt()),
        //               total: Duration(
        //                 milliseconds:
        //                     (messagesNotifier.voiceSlideDuration).toInt(),
        //               )))
        //     ],
        //   ),
        // );
        // ProgressBar(progress: progress, total: total)
        default:
          return Center(
              child: GestureDetector(
            onTap: () async {
              print("hh${message.media?.type}");
              await fileCreate(messagesNotifier.media(message.sid!),
                  fileName: message.media?.fileName);
              OpenFile.open(
                file?.path,
              );
            },
            child: Container(
                color: Colors.white,
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_copy,
                      color: Colors.grey,
                      size: 40,
                    ),
                    Text(
                      message.media?.fileName ?? "",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    )
                  ],
                )),
          ));
      }
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  File? file;
  fileCreate(bytes, {fileName, String? fileType}) async {
    var _fileDir = await getApplicationDocumentsDirectory();
    var type = fileType?.replaceAll("application/", "");
    file = File("${_fileDir.path}/${fileName}.${type}");
    file?.writeAsBytes(bytes);
    setState(() {});
  }

  Widget _buildParticipantsTyping(MessagesNotifier messagesNotifier) {
    final _currentlyTypingParticipants = messagesNotifier.currentlyTyping;

    return _currentlyTypingParticipants.isNotEmpty
        ? Text('${_currentlyTypingParticipants.join(', ')} is typing...')
        : Container();
  }

  Color? recdColor = Colors.black;
  Widget _buildMessageInputBar(MessagesNotifier messagesNotifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            child: Container(
              height: 55,
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: voiceIsRecording
                  ? Lottie.asset("assets/lottie/78453-recording.json",
                      controller: voiceRecdController)
                  : TextField(
                      controller: messagesNotifier.messageInputTextController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 8,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter Message',
                        contentPadding: EdgeInsets.only(
                            left: 12.0, right: 12.0, bottom: 4, top: 0),
                      ),
                    ),
            ),
          ),
          _buildSendButton(messagesNotifier),
          Visibility(
              visible: voiceIsRecording == false, child: fileSendButton()),
          Visibility(
              visible: voiceIsRecording == false,
              child: _buildMediaMessageButton()),
          _voiceRecordButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton(MessagesNotifier messagesNotifier) {
    final isEmptyInput =
        messagesNotifier.messageInputTextController.text.isEmpty;
    if (messagesNotifier.isSendingMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: isEmptyInput ? 8 : 44,
      child: isEmptyInput
          ? Container()
          : IconButton(
              color: Colors.blue,
              icon: Icon(Icons.send),
              onPressed: () {
                messagesNotifier.onSendMessagePressed();

                // getData();
                // messagesNotifier.loadConversation();
                messagesNotifier.loadMessages();
              },
            ),
    );
  }

  Widget fileSendButton() {
    return IconButton(
        color: Colors.blue,
        onPressed: () {
          messagesNotifier.onSendFileMessagePressed();
        },
        icon: Icon(Icons.file_copy_sharp));
  }

  Widget _buildMediaMessageButton() {
    return IconButton(
      color: Colors.blue,
      icon: Icon(Icons.add_photo_alternate_outlined),
      onPressed: messagesNotifier.onSendMediaMessagePressed,
    );
  }

  Widget _voiceRecordButton() {
    return GestureDetector(
        onTapDown: (v) async {
          recdColor = Colors.red;
          await messagesNotifier.startRecord();
          voiceIsRecording = true;

          micActive = true;
          setState(() {});
        },
        onTapUp: (v) async {
          micActive = false;
          voiceRecdController?.isCompleted == true;
          setState(() {});
          recdColor = Colors.black;
          voiceIsRecording = false;
          await messagesNotifier.stopRecord();

          // print("messagesNotifier.isRecording");  print(messagesNotifier.isRecording);  print("messagesNotifier.isRecording");
        },
        child: micActive!
            ? Container(
                height: 37,
                width: 37,
                child: Lottie.asset(
                  'assets/lottie/mic_icon.json',
                  animate: micActive,
                  controller: voiceRecdController,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                height: 37,
                width: 37,
                child: Center(
                    child: Icon(
                  Icons.mic,
                  color: Colors.white,
                )),
              ));
  }

  Widget _voicePlayButton(bytes, fileName) {
    return GestureDetector(
        onTap: () async {
          await messagesNotifier.startPlay(bytes, fileName);
          setState(() {});
        },
        child: Icon(Icons.play_arrow));
  }

  recordPopUp() {
    showDialog(
        context: context,
        builder: (_) {
          return Dialog(
            child: Container(height: 40),
          );
        });
  }

  Future _showManageParticipantsDialog() async {
    final controller = TextEditingController();
    messagesNotifier.getParticipants();
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Manage Participants'),
            content: ChangeNotifierProvider<MessagesNotifier>.value(
              value: messagesNotifier,
              child: Consumer<MessagesNotifier>(builder:
                  (BuildContext context, messagesNotifier, Widget? child) {
                final participants = messagesNotifier.participants;
                if (participants != null) {
                  return Container(
                      height: 200,
                      width: 140,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                              "Participants: ${messagesNotifier.participantCount}"),
                          Expanded(
                            child: ListView.builder(
                              itemCount: participants.length,
                              itemBuilder: (BuildContext context, int index) {
                                final participant = participants[index];
                                return Row(
                                  children: [
                                    Text(participant.identity ?? 'UNKNOWN'),
                                    InkWell(
                                      onTap: () async {
                                        await messagesNotifier
                                            .removeParticipant(participant);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(Icons.close),
                                      ),
                                    )
                                  ],
                                );
                              },
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                      label: Text('User Identity')),
                                  controller: controller,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await messagesNotifier
                                      .addUserByIdentity(controller.text);
                                  controller.text = '';
                                },
                                icon: Icon(Icons.add),
                              )
                            ],
                          ),
                        ],
                      ));
                } else {
                  return Container(
                    height: 200,
                    width: 140,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              }),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('CLOSE'),
              )
            ],
          );
        });
  }

  Future _showSwapAttributesDialog() async {
    final result = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Set Attributes Type'),
            content: ChangeNotifierProvider<MessagesNotifier>.value(
              value: messagesNotifier,
              child: Consumer<MessagesNotifier>(builder:
                  (BuildContext context, messagesNotifier, Widget? child) {
                final currentAttributesType =
                    messagesNotifier.conversation.attributes?.type;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ...AttributesType.values.map<Widget>((e) =>
                        RadioListTile<AttributesType>(
                            title: Text(EnumToString.convertToString(e)),
                            value: e,
                            groupValue: currentAttributesType,
                            onChanged: (AttributesType? value) =>
                                Navigator.of(context).pop(e))),
                  ],
                );
              }),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('CLOSE'),
              ),
              ElevatedButton(
                onPressed: messagesNotifier.getAttributes,
                child: Text('GET ATTRIBUTES'),
              ),
            ],
          );
        });
    if (result != null) {
      messagesNotifier.swapConversationAttributes(result);
    }
  }

  Future _showSwapMessageAttributesDialog(Message message) async {
    final result = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Set Attributes Type'),
            content: ChangeNotifierProvider<MessagesNotifier>.value(
              value: messagesNotifier,
              child: Consumer<MessagesNotifier>(builder:
                  (BuildContext context, messagesNotifier, Widget? child) {
                final currentAttributesType = message.attributes?.type;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ...AttributesType.values.map<Widget>((e) =>
                        RadioListTile<AttributesType>(
                            title: Text(EnumToString.convertToString(e)),
                            value: e,
                            groupValue: currentAttributesType,
                            onChanged: (AttributesType? value) =>
                                Navigator.of(context).pop(e))),
                  ],
                );
              }),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('CLOSE'),
              ),
              ElevatedButton(
                onPressed: messagesNotifier.getAttributes,
                child: Text('GET ATTRIBUTES'),
              ),
            ],
          );
        });
    if (result != null) {
      messagesNotifier.swapMessageAttributes(message, result);
    }
  }

  Future _showMyAttributesDialog() async {
    final currentAttributes = await messagesNotifier.getMyAttributes();
    final currentAttributesType = currentAttributes?.type;
    final result = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Set My Attributes Type'),
            content: ChangeNotifierProvider<MessagesNotifier>.value(
              value: messagesNotifier,
              child: Consumer<MessagesNotifier>(builder:
                  (BuildContext context, messagesNotifier, Widget? child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ...AttributesType.values.map<Widget>((e) =>
                        RadioListTile<AttributesType>(
                            title: Text(EnumToString.convertToString(e)),
                            value: e,
                            groupValue: currentAttributesType,
                            onChanged: (AttributesType? value) =>
                                Navigator.of(context).pop(e))),
                  ],
                );
              }),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('CLOSE'),
              ),
              ElevatedButton(
                onPressed: messagesNotifier.getMyAttributes,
                child: Text('GET ATTRIBUTES'),
              ),
            ],
          );
        });
    if (result != null) {
      messagesNotifier.swapMyAttributes(result);
    }
  }

  Future _destroyConversation() async {
    await messagesNotifier.destroy();
    Navigator.of(context).pop();
  }

  Future _updateFriendlyName() async {
    final newConversationName = await _showUpdateNameDialog(
      'Friendly Name',
      messagesNotifier.conversation.friendlyName,
    );
    if (newConversationName != null) {
      return messagesNotifier.setFriendlyName(newConversationName);
    }
  }

  Future _updateUniqueName() async {
    final newConversationName = await _showUpdateNameDialog(
      'Unique Name',
      messagesNotifier.conversation.uniqueName,
    );
    if (newConversationName != null) {
      return messagesNotifier.setUniqueName(newConversationName);
    }
  }

  Future<String?> _showUpdateNameDialog(
      String label, String? currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('New Conversation Name'),
            content: Container(
              height: 200,
              width: 140,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(label: Text(label)),
                          controller: controller,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                },
                child: Text('UPDATE'),
              ),
            ],
          );
        });
    return name;
  }

  Future _showMessageOptionsMenu(Message message, Offset position) async {
    final option = (await showMenu<MessageOptions>(
        context: context,
        position: RelativeRect.fromLTRB(
            position.dx, position.dy, position.dx, position.dy),
        items: [
          PopupMenuItem(
            value: MessageOptions.remove,
            child: Text('Remove'),
          ),
          PopupMenuItem(
            value: MessageOptions.updateMessageBody,
            child: Text('Update'),
          ),
          PopupMenuItem(
            value: MessageOptions.setAttributes,
            child: Text('Set Attributes'),
          ),
        ]));

    switch (option) {
      case MessageOptions.remove:
        _removeMessage(message);
        break;
      case MessageOptions.updateMessageBody:
        _showUpdateMessageBodyDialog(message);
        break;
      case MessageOptions.setAttributes:
        _showSwapMessageAttributesDialog(message);
        break;
      default:
        break;
    }
  }

  Future _removeMessage(Message message) async {
    print("asssssshhhhhhh");
    print(message.sid);
    print(message.messageIndex);
    print("asssssshhhhhhh");

    final removed = await messagesNotifier.removeMessage(
      message,
    );

    if (!removed) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Failed to Remove Message'),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _showUpdateMessageBodyDialog(Message message) async {
    final controller = TextEditingController(text: message.body);
    final messageBody = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Update Message'),
            content: Container(
              height: 200,
              width: 140,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration:
                              InputDecoration(label: Text('Message Body')),
                          controller: controller,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                },
                child: Text('UPDATE'),
              ),
            ],
          );
        });

    if (messageBody != null) {
      message.updateMessageBody(messageBody);
    }
  }
}

enum MessagesPageMenuOptions {
  participants,
  destroyConversation,
  swapAttributes,
  myAttributes,
  clearChat
}

enum MessageOptions {
  remove,
  setAttributes,
  updateMessageBody,
}
