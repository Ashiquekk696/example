import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:twilio_conversations/twilio_conversations.dart';
import 'package:twilio_conversations_example/messages/messages_page2.dart';

import '../conversations/conversations_notifier.dart';
import '../messages/messages_notifier.dart';

class VoiceSlider extends StatefulWidget {
  VoiceSlider({
    Key? key,
    required this.notifier,
    required this.message,
  }) : super(key: key);

  Message message;

  //final Conversation conversation;
  MessagesNotifier notifier;
  // final ConversationClient client;
  late final ConversationsNotifier conversationNotifier;
  @override
  State<VoiceSlider> createState() => _VoiceSliderState();
}

class _VoiceSliderState extends State<VoiceSlider> {
  @override
  void initState() {
    messagesNotifier = widget.notifier;

    super.initState();
  }

  late MessagesNotifier messagesNotifier;
  var selctdfileName;
  Widget _voicePlayButton() {
    return GestureDetector(
        onTap: () async {
          await messagesNotifier.startPlay(
              messagesNotifier.media(widget.message.sid!),
              widget.message.media?.fileName);

          setState(() {});
        },
        child: Icon(Icons.play_arrow));
  }

  @override
  Widget build(BuildContext context) {
    print("${messagesNotifier.voiceSlidePosition}hhhiii");
    return

        // Container(
        //   height: 50,
        //   color: Colors.white,
        //   child: Row(
        //     children: [
        //       _voicePlayButton(
        //           //messagesNotifier.media(widget.messageSid),
        //           widget.mediaBytes,
        //           widget.mediaFileName),
        //       Container(
        //           height: 15,
        //           width: 155,
        //           child: ProgressBar(
        //               progress: Duration(
        //                   milliseconds:
        //                       messagesNotifier.voiceSlidePosition.toInt()),
        //               total: Duration(
        //                   milliseconds:
        //                       messagesNotifier.voiceSlideDuration.toInt()))),
        //       GestureDetector(
        //         onTap: () {
        //           widget.onTaP();
        //         },
        //         child: Icon(
        //           Icons.baby_changing_station_outlined,
        //           size: 33,
        //         ),
        //       )
        //     ],
        //   ),
        // );

        Container(
      height: 50,
      color: Colors.white,
      child: Row(
        children: [
          _voicePlayButton(
              //messagesNotifier.media(widget.messageSid),
              ),
          Container(
            height: 15,
            child: Slider(
              value: messagesNotifier.voiceSlidePosition,
              min: 0,
              max: messagesNotifier.voiceSlideDuration,
              onChanged: (value) async {
                // widget.voiceSlidePosition = value;
                //widget.voiceSlidePosition = value;

                await messagesNotifier.myPlayer?.seekToPlayer(Duration(
                    milliseconds:
                        (messagesNotifier.voiceSlidePosition / 1000).toInt()));
                // await messagesNotifier.seekNowPosition();
                setState(() {});
              },
            ),
          )
        ],
      ),
    );
  }
}
