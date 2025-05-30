
import 'package:customer/Helper/Color.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'quality_links.dart';
import 'dart:async';

class FullscreenPlayer extends StatefulWidget {
  final String id;
  final bool? autoPlay;
  final bool? looping;
  final VideoPlayerController? controller;
  final position;
  final Future<void>? initFuture;
  final String? qualityValue;
  const FullscreenPlayer({
    required this.id,
    this.autoPlay,
    this.looping,
    this.controller,
    this.position,
    this.initFuture,
    this.qualityValue,
    super.key,
  });
  @override
  _FullscreenPlayerState createState() => _FullscreenPlayerState(
        id,
        autoPlay,
        looping,
        controller,
        position,
        initFuture,
        qualityValue,
      );
}

class _FullscreenPlayerState extends State<FullscreenPlayer> {
  final String _id;
  bool? autoPlay = false;
  bool? looping = false;
  bool _overlay = true;
  bool fullScreen = true;
  VideoPlayerController? controller;
  VideoPlayerController? _controller;
  int? position;
  Future<void>? initFuture;
  var qualityValue;
  _FullscreenPlayerState(
    this._id,
    this.autoPlay,
    this.looping,
    this.controller,
    this.position,
    this.initFuture,
    this.qualityValue,
  );
  late QualityLinks _quality;
  late Map _qualityValues;
  bool _seek = true;
  double? videoHeight;
  double? videoWidth;
  late double videoMargin;
  double doubleTapRMarginFS = 36;
  double? doubleTapRWidthFS = 700;
  double doubleTapRHeightFS = 300;
  double doubleTapLMarginFS = 10;
  double? doubleTapLWidthFS = 700;
  double? doubleTapLHeightFS = 400;
  @override
  void initState() {
    _controller = controller;
    if (autoPlay!) _controller!.play();
    _quality = QualityLinks(_id);
    _quality.getQualitiesSync().then(
      (value) {
        _qualityValues = value;
      },
    );
    setState(
      () {
        SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
        );
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: [SystemUiOverlay.bottom],);
      },
    );
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        setState(
          () {
            _controller!.pause();
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp],);
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
            );
          },
        );
        Navigator.pop(context, _controller!.value.position.inSeconds);
      },
      child: Scaffold(
        body: Center(
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              GestureDetector(
                child: FutureBuilder(
                  future: initFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      final double delta = MediaQuery.of(context).size.width -
                          MediaQuery.of(context).size.height *
                              _controller!.value.aspectRatio;
                      if (MediaQuery.of(context).orientation ==
                              Orientation.portrait ||
                          delta < 0) {
                        videoHeight = MediaQuery.of(context).size.width /
                            _controller!.value.aspectRatio;
                        videoWidth = MediaQuery.of(context).size.width;
                        videoMargin = 0;
                      } else {
                        videoHeight = MediaQuery.of(context).size.height;
                        videoWidth =
                            videoHeight! * _controller!.value.aspectRatio;
                        videoMargin =
                            (MediaQuery.of(context).size.width - videoWidth!) /
                                2;
                      }
                      doubleTapRWidthFS = videoWidth;
                      doubleTapRHeightFS = videoHeight! - 36;
                      doubleTapLWidthFS = videoWidth;
                      doubleTapLHeightFS = videoHeight;
                      if (_seek && fullScreen) {
                        _controller!.seekTo(Duration(seconds: position!));
                        _seek = false;
                      }
                      if (_seek && _controller!.value.duration.inSeconds > 2) {
                        _controller!.seekTo(Duration(seconds: position!));
                        _seek = false;
                      }
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                          overlays: [SystemUiOverlay.bottom],);
                      return Stack(
                        children: <Widget>[
                          Container(
                            height: videoHeight,
                            width: videoWidth,
                            margin: EdgeInsets.only(left: videoMargin),
                            child: VideoPlayer(_controller!),
                          ),
                          _videoOverlay(),
                        ],
                      );
                    } else {
                      return Center(
                        heightFactor: 6,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primarytheme,
                          ),
                        ),
                      );
                    }
                  },
                ),
                onTap: () {
                  setState(
                    () {
                      _overlay = !_overlay;
                      if (_overlay) {
                        doubleTapRHeightFS = videoHeight! - 36;
                        doubleTapLHeightFS = videoHeight! - 10;
                        doubleTapRMarginFS = 36;
                        doubleTapLMarginFS = 10;
                      } else if (!_overlay) {
                        doubleTapRHeightFS = videoHeight! + 36;
                        doubleTapLHeightFS = videoHeight;
                        doubleTapRMarginFS = 0;
                        doubleTapLMarginFS = 0;
                      }
                    },
                  );
                },
              ),
              GestureDetector(
                child: Container(
                  width: doubleTapLWidthFS! / 2 - 30,
                  height: doubleTapLHeightFS! - 44,
                  margin: EdgeInsets.fromLTRB(
                    0,
                    0,
                    doubleTapLWidthFS! / 2 + 30,
                    40,
                  ),
                  decoration: const BoxDecoration(),
                ),
                onTap: () {
                  setState(
                    () {
                      _overlay = !_overlay;
                      if (_overlay) {
                        doubleTapRHeightFS = videoHeight! - 36;
                        doubleTapLHeightFS = videoHeight! - 10;
                        doubleTapRMarginFS = 36;
                        doubleTapLMarginFS = 10;
                      } else if (!_overlay) {
                        doubleTapRHeightFS = videoHeight! + 36;
                        doubleTapLHeightFS = videoHeight;
                        doubleTapRMarginFS = 0;
                        doubleTapLMarginFS = 0;
                      }
                    },
                  );
                },
                onDoubleTap: () {
                  setState(
                    () {
                      _controller!.seekTo(
                        Duration(
                            seconds:
                                _controller!.value.position.inSeconds - 10,),
                      );
                    },
                  );
                },
              ),
              GestureDetector(
                child: Container(
                  width: doubleTapRWidthFS! / 2 - 45,
                  height: doubleTapRHeightFS - 80,
                  margin: EdgeInsets.fromLTRB(
                    doubleTapRWidthFS! / 2 + 45,
                    0,
                    0,
                    doubleTapLMarginFS + 20,
                  ),
                  decoration: const BoxDecoration(),
                ),
                onTap: () {
                  setState(
                    () {
                      _overlay = !_overlay;
                      if (_overlay) {
                        doubleTapRHeightFS = videoHeight! - 36;
                        doubleTapLHeightFS = videoHeight! - 10;
                        doubleTapRMarginFS = 36;
                        doubleTapLMarginFS = 10;
                      } else if (!_overlay) {
                        doubleTapRHeightFS = videoHeight! + 36;
                        doubleTapLHeightFS = videoHeight;
                        doubleTapRMarginFS = 0;
                        doubleTapLMarginFS = 0;
                      }
                    },
                  );
                },
                onDoubleTap: () {
                  setState(
                    () {
                      _controller!.seekTo(
                        Duration(
                          seconds: _controller!.value.position.inSeconds + 10,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        final children = <Widget>[];
        _qualityValues.forEach(
          (elem, value) => children.add(
            ListTile(
              title: Text(
                ' $elem fps',
                style: const TextStyle(
                  fontFamily: 'ubuntu',
                ),
              ),
              onTap: () => {
                setState(
                  () {
                    _controller!.pause();
                    _controller =
                        VideoPlayerController.networkUrl(Uri.parse(value));
                    _controller!.setLooping(true);
                    _seek = true;
                    initFuture = _controller!.initialize();
                    _controller!.play();
                  },
                ),
              },
            ),
          ),
        );
        return SizedBox(
          height: videoHeight,
          child: ListView(
            children: children,
          ),
        );
      },
    );
  }

  Widget _videoOverlay() {
    return _overlay
        ? Stack(
            children: <Widget>[
              GestureDetector(
                child: Center(
                  child: Container(
                    width: videoWidth,
                    height: videoHeight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Color(0x662F2C47),
                          Color(0x662F2C47),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: IconButton(
                  padding: EdgeInsets.only(
                    top: videoHeight! / 2 - 50,
                    bottom: videoHeight! / 2 - 30,
                  ),
                  icon: _controller!.value.isPlaying
                      ? const Icon(Icons.pause, size: 60.0)
                      : const Icon(Icons.play_arrow, size: 60.0),
                  onPressed: () {
                    setState(
                      () {
                        _controller!.value.isPlaying
                            ? _controller!.pause()
                            : _controller!.play();
                      },
                    );
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  top: videoHeight! - 80,
                  left: videoWidth! + videoMargin - 50,
                ),
                child: IconButton(
                    alignment: AlignmentDirectional.center,
                    icon: const Icon(Icons.fullscreen, size: 30.0),
                    onPressed: () {
                      setState(
                        () {
                          _controller!.pause();
                          SystemChrome.setPreferredOrientations(
                            [
                              DeviceOrientation.portraitDown,
                              DeviceOrientation.portraitUp,
                            ],
                          );
                          SystemChrome.setEnabledSystemUIMode(
                            SystemUiMode.manual,
                            overlays: [
                              SystemUiOverlay.top,
                              SystemUiOverlay.bottom,
                            ],
                          );
                        },
                      );
                      Navigator.pop(
                          context, _controller!.value.position.inSeconds,);
                    },),
              ),
              Container(
                margin: EdgeInsets.only(left: videoWidth! + videoMargin - 48),
                child: IconButton(
                  icon: const Icon(Icons.settings, size: 26.0),
                  onPressed: () {
                    position = _controller!.value.position.inSeconds;
                    _seek = true;
                    _settingModalBottomSheet(context);
                    setState(() {});
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  top: videoHeight! - 40,
                  left: videoMargin,
                ),
                child: _videoOverlaySlider(),
              ),
            ],
          )
        : const Center();
  }

  Widget _videoOverlaySlider() {
    return ValueListenableBuilder(
      valueListenable: _controller!,
      builder: (context, VideoPlayerValue value, child) {
        if (!value.hasError && value.isInitialized) {
          return Row(
            children: <Widget>[
              Container(
                width: 46,
                alignment: Alignment.center,
                child: Text(
                  '${value.position.inMinutes}:${value.position.inSeconds - value.position.inMinutes * 60}',
                  style: const TextStyle(
                    fontFamily: 'ubuntu',
                  ),
                ),
              ),
              SizedBox(
                height: 20,
                width: videoWidth! - 92,
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Theme.of(context).colorScheme.primarytheme,
                    backgroundColor: const Color(0x5515162B),
                    bufferedColor: Theme.of(context)
                        .colorScheme
                        .primarytheme
                        .withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                ),
              ),
              Container(
                width: 46,
                alignment: Alignment.center,
                child: Text(
                  '${value.duration.inMinutes}:${value.duration.inSeconds - value.duration.inMinutes * 60}',
                  style: const TextStyle(
                    fontFamily: 'ubuntu',
                  ),
                ),
              ),
            ],
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
