import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/room_model.dart';
import 'player_sync.dart';

/// مشغّل الروابط المباشرة (mp4 / m3u8 / webm...) مع مزامنة جماعية
class DirectPlayerBox extends StatefulWidget {
  const DirectPlayerBox({
    super.key,
    required this.url,
    required this.isHost,
    required this.myUid,
    required this.autoplay,
    required this.playbackStream,
    required this.onLocalPlayback,
    this.initialPlayback,
  });

  final String url;
  final bool isHost;
  final String myUid;
  final bool autoplay;
  final Stream<PlaybackState> playbackStream;
  final LocalPlaybackCallback onLocalPlayback;
  final PlaybackState? initialPlayback;

  @override
  State<DirectPlayerBox> createState() => _DirectPlayerBoxState();
}

class _DirectPlayerBoxState extends State<DirectPlayerBox>
    with PlaybackSyncMixin {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  String? _error;
  bool _initializing = true;
  bool _applyingRemote = false;

  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  bool? _lastPlaying;
  double _lastPosition = -1;

  StreamSubscription<PlaybackState>? _remoteSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      _video = controller;
      controller.addListener(_onVideoUpdate);
      await controller.initialize();

      _chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: widget.autoplay,
        looping: false,
        aspectRatio:
            controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
        allowedScreenSleep: false,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryLight,
          handleColor: AppColors.accent,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        placeholder: Container(color: Colors.black),
        errorBuilder: (_, errorMessage) =>
            _errorView(errorMessage),
      );

      _remoteSub = widget.playbackStream.listen(_applyRemote);
      if (!widget.isHost && widget.initialPlayback != null) {
        await _applyRemote(widget.initialPlayback!);
      }
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر تشغيل هذا الرابط. قد يكون الموقع يمنع التشغيل المباشر.';
          _initializing = false;
        });
      }
    }
  }

  void _onVideoUpdate() {
    final controller = _video;
    if (controller == null || !controller.value.isInitialized) return;
    if (_applyingRemote || !widget.isHost) return;

    final playing = controller.value.isPlaying;
    final position = controller.value.position.inMilliseconds / 1000.0;
    final now = DateTime.now();

    final stateChanged =
        _lastPlaying != null && _lastPlaying != playing;
    final seeked = (position - _lastPosition).abs() > 2.5;
    final periodic =
        playing && now.difference(_lastPush).inSeconds >= 4;

    if (_lastPlaying == null || stateChanged || seeked || periodic) {
      widget.onLocalPlayback(playing, position);
      _lastPush = now;
      _lastPlaying = playing;
      _lastPosition = position;
    }
  }

  Future<void> _applyRemote(PlaybackState state) async {
    final controller = _video;
    final chewie = _chewie;
    if (controller == null || chewie == null) return;
    if (!controller.value.isInitialized) return;

    final target = resolveRemotePosition(
      state,
      isHost: widget.isHost,
      myUid: widget.myUid,
    );
    if (target == null) return;

    _applyingRemote = true;
    try {
      await controller.seekTo(Duration(milliseconds: (target * 1000).round()));
      if (state.isPlaying) {
        await controller.play();
      } else {
        await controller.pause();
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 900));
      _applyingRemote = false;
    }
  }

  @override
  void dispose() {
    _remoteSub?.cancel();
    _video?.removeListener(_onVideoUpdate);
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  Widget _errorView(String message) => Container(
        color: Colors.black,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.live, size: 42),
            const SizedBox(height: 10),
            Text(
              _error ?? message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.7),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _errorView(_error!),
        ),
      );
    }
    if (_initializing || _chewie == null || _video == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewie!),
      ),
    );
  }
}
