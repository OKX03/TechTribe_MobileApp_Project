import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;

  Stream<DurationState> get _durationStateStream =>
      Rx.combineLatest2<Duration, Duration, DurationState>(
        _player.positionStream,
        _player.durationStream.map((d) => d ?? Duration.zero),
        (position, duration) => DurationState(position: position, total: duration),
      );

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer()..setUrl(widget.audioUrl);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? false;
        final isCompleted = playerState?.processingState == ProcessingState.completed;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: IconButton(
              icon: Icon(
                isPlaying && !isCompleted
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.white,
                size: 26,
              ),
              onPressed: _togglePlayPause,
            ),
            title: StreamBuilder<DurationState>(
              stream: _durationStateStream,
              builder: (context, snapshot) {
                final durationState = snapshot.data;
                final position = durationState?.position ?? Duration.zero;
                final total = durationState?.total ?? Duration.zero;

                return SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    activeColor: Colors.white,
                    inactiveColor: Colors.white54,
                    min: 0.0,
                    max: total.inMilliseconds.toDouble(),
                    value: position.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                    onChanged: (value) {
                      _player.seek(Duration(milliseconds: value.round()));
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class DurationState {
  final Duration position;
  final Duration total;

  DurationState({required this.position, required this.total});
}


// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';

// class AudioPlayerWidget extends StatefulWidget {
//   final String audioUrl;

//   const AudioPlayerWidget({super.key, required this.audioUrl});

//   @override
//   State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
// }

// class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
//   late final AudioPlayer _player;
//   bool isPlaying = false;

//   @override
//   void initState() {
//     super.initState();
//     _player = AudioPlayer();
//     _player.setUrl(widget.audioUrl).then((_) {
//       setState(() {});
//     });
//   }


//   @override
//   void dispose() {
//     _player.dispose();
//     super.dispose();
//   }

//   void togglePlay() async {
//     if (isPlaying) {
//       await _player.pause();
//     } else {
//       await _player.play();
//     }
//     setState(() => isPlaying = !isPlaying);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filename = widget.audioUrl.split('/').last;

//     return Container(
//       // margin: const EdgeInsets.symmetric(vertical: 4),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//         ),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//         leading: IconButton(
//           icon: Icon(
//             isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
//             color: Colors.white,
//             size: 24, 
//           ),
//           onPressed: togglePlay,
//         ),
//         title: Text(
//           filename,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         onTap: togglePlay,
//       ),
//     );
//   }
// }
