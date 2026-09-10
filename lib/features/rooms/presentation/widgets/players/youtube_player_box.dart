import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../data/room_model.dart';
import 'player_sync.dart';

/// مشغّل يوتيوب مدمج مع مزامنة جماعية للتشغيل/الإيقاف/التقديم
class YoutubePlayerBox extends StatefulWidget {
  const YoutubePlayerBox({
    super.key,
    required this.videoId,
    required this.isHost,
    required this.myUid,
    required this.playbackStream,
    required this.onLocalPlayback,
    this.initialPlayback,
  });

  final String videoId;
  final bool isHost;
  final String myUid;
  final Stream<PlaybackState> playbackStream;
  final LocalPlaybackCallback onLocalPlayback;
  final PlaybackState? initialPlayback;

  @override
  State<YoutubePlayerBox> createState() => _YoutubePlayerBoxState();
}

class _YoutubePlayerBoxState extends State<YoutubePlayerBox>
    with PlaybackSyncMixin {
  late final YoutubePlayerController _controller;

  StreamSubscription<YoutubePlayerValue>? _valueSub;
  StreamSubscription<YoutubeVideoState>? _positionSub;
  StreamSubscription<PlaybackState>? _remoteSub;

  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  PlayerState? _lastState;
  Duration _lastPosition = Duration.zero;
  DateTime _lastPositionAt = DateTime.now();
  bool _initialHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        showVideoAnnotations: false,
        enableCaption: false,
        interfaceLanguage: 'ar',
        color: 'white',
        videoStateUpdateInterval: 250,
      ),
    );
    _valueSub = _controller.listen(_onValue);
    _positionSub = _controller.videoStateStream.listen(_onPosition);
    _remoteSub = widget.playbackStream.listen(_applyRemote);
    _prepare();
  }

  Future<void> _prepare() async {
    double startSeconds = 0;
    final initial = widget.initialPlayback;
    if (!widget.isHost && initial != null) {
      final elapsed = DateTime.now().difference(initial.updatedAt).inMilliseconds /
          1000;
      startSeconds =
          (initial.positionSeconds + elapsed).clamp(0, 100000).toDouble();
    }
    // الجسر الداخلي يصفّ الأوامر حتى اكتمال تهيئة المشغّل
    await _controller.loadVideoById(
      videoId: widget.videoId,
      startSeconds: startSeconds > 1 ? startSeconds : null,
    );
  }

  // ---- أحداث محلية (يرفعها المضيف) ----

  void _onValue(YoutubePlayerValue value) {
    final state = value.playerState;

    // ضيف متأخر وكان البث متوقفًا: نوقف الفيديو بعد التحميل
    if (!widget.isHost) {
      if (!_initialHandled && state == PlayerState.playing) {
        _initialHandled = true;
        final initial = widget.initialPlayback;
        if (initial != null && !initial.isPlaying) {
          _controller.pauseVideo();
        }
      }
      return;
    }

    final wasPlaying = _lastState == PlayerState.playing ||
        _lastState == PlayerState.buffering;
    final isPlaying = state == PlayerState.playing ||
        state == PlayerState.buffering;

    if (_lastState != null && wasPlaying != isPlaying) {
      widget.onLocalPlayback(
        isPlaying,
        _lastPosition.inMilliseconds / 1000.0,
      );
      _lastPush = DateTime.now();
    }
    _lastState = state;
  }

  void _onPosition(YoutubeVideoState event) {
    if (!widget.isHost) return;
    final pos = event.position;
    final now = DateTime.now();

    // كشف التقديم/الإرجاع اليدوي
    final expected =
        _lastPosition + now.difference(_lastPositionAt);
    final seeked = (pos - expected).inMilliseconds.abs() > 2500;

    final playing = _controller.value.playerState == PlayerState.playing ||
        _controller.value.playerState == PlayerState.buffering;
    final periodic =
        playing && now.difference(_lastPush).inSeconds >= 4;

    if (seeked || periodic) {
      widget.onLocalPlayback(
        playing,
        pos.inMilliseconds / 1000.0,
      );
      _lastPush = now;
    }
    _lastPosition = pos;
    _lastPositionAt = now;
  }

  // ---- مزامنة قادمة من المضيف ----

  Future<void> _applyRemote(PlaybackState state) async {
    final target = resolveRemotePosition(
      state,
      isHost: widget.isHost,
      myUid: widget.myUid,
    );
    if (target == null) return;
    await _controller.seekTo(seconds: target, allowSeekAhead: true);
    if (state.isPlaying) {
      await _controller.playVideo();
    } else {
      await _controller.pauseVideo();
    }
  }

  @override
  void dispose() {
    _valueSub?.cancel();
    _positionSub?.cancel();
    _remoteSub?.cancel();
    unawaited(_controller.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
            backgroundColor: Colors.black,
          ),
        ),
      ),
    );
  }
}
