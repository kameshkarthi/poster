import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:dio/dio.dart';
import 'dart:ui' as ui;
import 'Database.dart';
import 'Listview.dart';

class FullScreen extends StatefulWidget {
  final ImageModel imageModel;
  final File file;

  const FullScreen(this.file, this.imageModel, {super.key});

  @override
  State<FullScreen> createState() => _FullScreenState();
}

class _FullScreenState extends State<FullScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ExpandableBottomSheetState> _bottomSheetKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  late AnimationController _controller;
  late StreamController<bool> _isFavoriteController;
  bool _isLoading = false;
  bool _isDownloading = false;
  String _downloadProgress = '0';
  bool _isPaidUnlocked = false;
  ui.Image? _imageInfo;
  List<String> _tags = [];
  ExpansionStatus _sheetStatus = ExpansionStatus.contracted;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _isFavoriteController = StreamController<bool>.broadcast();
    _scrollController = ScrollController();
    _initialize();
  }

  Future<void> _initialize() async {
    _getImageInfo();
    _checkPaidStatus();
    _isFavoriteController.addStream(
      Stream.fromFuture(ImageDB().isFavorite(widget.imageModel.id)),
    );
  }

  Future<void> _getImageInfo() async {
    if (widget.imageModel.tags != null && widget.imageModel.tags!.length >= 2) {
      _tags = widget.imageModel.tags!.take(2).toList();
    }
    final completer = Completer<ui.Image>();
    NetworkImage(widget.imageModel.imageUrl ?? '')
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener(
          (imageInfo, synchronousCall) => completer.complete(imageInfo.image),
      onError: (error, stackTrace) => completer.completeError(error, stackTrace),
    ));
    try {
      final image = await completer.future;
      if (mounted) {
        setState(() {
          _imageInfo = image;
        });
      }
    } catch (e) {
      print('Error loading image info: $e');
    }
  }

  Future<void> _checkPaidStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final suggestions = prefs.getStringList('suggestions_list') ?? [];
    if (mounted && suggestions.contains(widget.imageModel.id)) {
      setState(() {
        _isPaidUnlocked = true;
      });
    }
  }

  Future<void> _savePaidStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final suggestions = prefs.getStringList('suggestions_list') ?? [];
    if (!suggestions.contains(widget.imageModel.id)) {
      suggestions.insert(0, widget.imageModel.id);
      await prefs.setStringList('suggestions_list', suggestions);
      if (mounted) {
        setState(() {
          _isPaidUnlocked = true;
        });
      }
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    _isFavoriteController.close();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _increaseDownloadCount() async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docRef = FirebaseFirestore.instance.collection('General').doc(widget.imageModel.id);
        final docSnapshot = await transaction.get(docRef);
        transaction.update(docRef, {
          'downloadCount': (docSnapshot.get('downloadCount') ?? 0) + 1,
        });
      });
    } catch (e) {
      print('Error updating download count: $e');
    }
  }

  void _toggleBottomSheet() {
    if (_controller.isCompleted) {
      _controller.reverse();
      _bottomSheetKey.currentState?.contract();
      setState(() => _sheetStatus = ExpansionStatus.contracted);
    } else {
      _controller.forward();
      _bottomSheetKey.currentState?.expand();
      setState(() => _sheetStatus = ExpansionStatus.expanded);
    }
  }

  Future<void> _downloadImage(String url) async {
    setState(() => _isDownloading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Poster-${DateTime.now().millisecondsSinceEpoch}.jpeg';
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = ((received / total) * 100).toStringAsFixed(0);
            });
          }
        },
      );
      await _increaseDownloadCount();
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Downloaded Successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black.withOpacity(0.7),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to download image');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = '0';
        });
      }
    }
  }

  Future<void> _setWallpaper(String url) async {
    setState(() => _isLoading = true);
    try {
      // final stream = Wallpaper.imageDownloadProgress(url);
      // stream.listen(
      //       (progress) {
      //     if (mounted) {
      //       setState(() {
      //         _downloadProgress = progress;
      //         _isDownloading = true;
      //       });
      //     }
      //   },
      //   onDone: () async {
      //     final result = await Wallpaper.homeScreen();
      //     if (mounted) {
      //       setState(() {
      //         _isLoading = false;
      //         _isDownloading = false;
      //         _downloadProgress = '0';
      //       });
      //       Fluttertoast.showToast(
      //         msg: 'Wallpaper set successfully: $result',
      //         toastLength: Toast.LENGTH_SHORT,
      //         gravity: ToastGravity.CENTER,
      //         backgroundColor: Colors.black.withOpacity(0.7),
      //         textColor: Colors.white,
      //         fontSize: 16.0,
      //       );
      //     }
      //   },
      //   onError: (error) {
      //     if (mounted) {
      //       setState(() {
      //         _isLoading = false;
      //         _isDownloading = false;
      //       });
      //       _showSnackBar('Failed to set wallpaper: $error');
      //     }
      //   },
      // );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDownloading = false;
        });
        _showSnackBar('Failed to set wallpaper: $e');
      }
    }
  }

  void _showResolutionDialog(int task, String original, String? adopted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
        ),
        contentPadding: const EdgeInsets.only(top: 10.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.stay_primary_portrait, color: Colors.white),
              subtitle: Text(
                'HD, 1920 x 1080',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              title: const Text('Resized', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                task == 1 ? _downloadImage(adopted ?? original) : _setWallpaper(adopted ?? original);
              },
            ),
            const SizedBox(height: 5.0),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.white),
              subtitle: Text(
                _imageInfo != null ? '4K, ${_imageInfo!.width} x ${_imageInfo!.height}' : '4K',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              title: const Text('Original', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                task == 1 ? _downloadImage(original) : _setWallpaper(original);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  void _changeFavoriteStatus(bool isFavorite) async {
    try {
      final success = isFavorite
          ? await ImageDB().deleteFavorite(widget.imageModel.id) > 0
          : await ImageDB().insertFavoriteImage(widget.imageModel) != -1;
      if (success) {
        _isFavoriteController.add(!isFavorite);
        Fluttertoast.showToast(
          msg: isFavorite ? 'Removed from favorites' : 'Added to favorites',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black.withOpacity(0.7),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        _showSnackBar('Failed to update favorites');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showLockedContentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unlock this wallpaper by watching an ad or buying a subscription.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () async {
                    setState(() => _isLoading = true);
                  },
                  child: const Text('Watch ad'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        ),
                        contentPadding: const EdgeInsets.all(15.0),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Coming Soon',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            const Text(
                              'The subscription feature is under development. Sorry for the inconvenience.',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20.0),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Buy subscription'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final queryData = MediaQuery.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      body: StreamBuilder<bool>(
        stream: _isFavoriteController.stream.distinct(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading favorite status', style: TextStyle(color: Colors.white)));
          }
          final isFavorite = snapshot.data ?? false;
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: _isPaidUnlocked || widget.imageModel.paid == 0 ? _toggleBottomSheet : null,
                child: Hero(
                  tag: widget.imageModel.id, // Use stable ID for Hero animation
                  child: CachedNetworkImage(
                    imageUrl: widget.imageModel.adopted ?? widget.imageModel.imageUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          widget.file,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white),
                        ),
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              ),
              if (_isPaidUnlocked || widget.imageModel.paid == 0)
                ExpandableBottomSheet(
                  key: _bottomSheetKey,
                  onIsExtendedCallback: () => setState(() => _sheetStatus = ExpansionStatus.expanded),
                  onIsContractedCallback: () => setState(() => _sheetStatus = ExpansionStatus.contracted),
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SafeArea(
                        child: Transform.translate(
                          offset: Offset(0, -_controller.value * 200),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.7),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20.0),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  persistentHeader: SafeArea(
                    child: Transform.translate(
                      offset: Offset(0, _controller.value * 140),
                      child: Padding(
                        padding: _sheetStatus == ExpansionStatus.contracted
                            ? const EdgeInsets.only(bottom: 15, left: 20.0, right: 20.0)
                            : const EdgeInsets.only(top: 6.0),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.85),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(25.0),
                              topRight: const Radius.circular(25.0),
                              bottomRight: _sheetStatus == ExpansionStatus.expanded ? Radius.zero : const Radius.circular(25.0),
                              bottomLeft: _sheetStatus == ExpansionStatus.expanded ? Radius.zero : const Radius.circular(25.0),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: IconButton(
                                        icon: Icon(
                                          _sheetStatus == ExpansionStatus.contracted
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: Colors.white,
                                        ),
                                        onPressed: _toggleBottomSheet,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => _changeFavoriteStatus(isFavorite),
                                      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                                    ),
                                    IconButton(
                                      tooltip: 'Download',
                                      icon: _isDownloading
                                          ? Text(_downloadProgress, style: const TextStyle(color: Colors.white))
                                          : const Icon(Icons.file_download, color: Colors.white),
                                      onPressed: () => _showResolutionDialog(1, widget.imageModel.imageUrl ?? '', widget.imageModel.adopted),
                                    ),
                                    CircleAvatar(
                                      backgroundColor: Colors.black.withOpacity(0),
                                      radius: 25.0,
                                      child: _isLoading
                                          ? const SizedBox(
                                        width: 10.0,
                                        height: 10.0,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : IconButton(
                                        tooltip: 'Set Wallpaper',
                                        icon: const Icon(Icons.format_paint, size: 20.0, color: Colors.white),
                                        onPressed: () => _showResolutionDialog(2, widget.imageModel.imageUrl ?? '', widget.imageModel.adopted),
                                      ),
                                    ),
                                    const SizedBox(width: 15.0),
                                  ],
                                ),
                                const SizedBox(height: 15.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text('Downloads', style: GoogleFonts.amaranth(color: Colors.white.withOpacity(0.7), fontSize: 15.0)),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          (widget.imageModel.downloadCount ?? 0).toString(),
                                          style: GoogleFonts.amaranth(color: Colors.white, fontSize: 15.0),
                                        ),
                                      ],
                                    ),
                                    Container(width: 1, height: 40.0, color: Colors.white),
                                    Column(
                                      children: [
                                        Text('Views', style: GoogleFonts.amaranth(color: Colors.white.withOpacity(0.7), fontSize: 15.0)),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          (widget.imageModel.viewCount ?? 0).toString(),
                                          style: GoogleFonts.amaranth(color: Colors.white, fontSize: 15.0),
                                        ),
                                      ],
                                    ),
                                    Container(width: 1, height: 40.0, color: Colors.white),
                                    Column(
                                      children: [
                                        Text('Uploaded', style: GoogleFonts.amaranth(color: Colors.white.withOpacity(0.7), fontSize: 15.0)),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          widget.imageModel.uploadedTime != null
                                              ? timeago.format(widget.imageModel.uploadedTime!)
                                              : 'Unknown',
                                          style: GoogleFonts.amaranth(color: Colors.white, fontSize: 15.0),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  expandableContent: ClipRRect(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0),topRight: Radius.circular(30.0)),
                    child: Container(
                      height: queryData.size.height / 1.3,
                      color: Colors.black,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50.0),
                                child: Container(
                                  width: 55.0,height: 3.0,color: Colors.grey.withValues(alpha: 0.6),),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(25.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Source:', style: GoogleFonts.amaranth(color: Colors.white.withOpacity(0.7), fontSize: 15.0)),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                                  child: Text(
                                    widget.imageModel.name ?? 'Unknown',
                                    style: GoogleFonts.amaranth(color: Colors.white, fontSize: 15.0),
                                  ),
                                ),
                                const SizedBox(height: 15.0),
                                Text('License:', style: GoogleFonts.amaranth(color: Colors.white.withOpacity(0.7), fontSize: 15.0)),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10.0),
                                  child: Text(
                                    widget.imageModel.license != null ? '${widget.imageModel.license} License' : 'Unknown',
                                    style: GoogleFonts.amaranth(color: Colors.white, fontSize: 15.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Divider(color: Colors.white.withOpacity(0.8), thickness: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'Related Wallpapers',
                              style: GoogleFonts.amaranth(color: Colors.white.withOpacity(0.7), fontSize: 15.0),
                            ),
                          ),
                          Expanded(
                            child: MyListView(
                              title: 'Related',
                              stream:  FirebaseFirestore.instance
                                  .collection('General')
                                  .where('tag', arrayContainsAny: _tags.isNotEmpty ? _tags : ['default'])
                                  .orderBy('uploadedTime', descending: true)
                                  .snapshots()
                                  .map(mapper),
                             backgroundColor:  Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: CircleAvatar(
                          radius: 20.0,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 80.0),
                        child: FloatingActionButton(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                              : const Icon(Icons.lock, color: Colors.white),
                          onPressed: _showLockedContentDialog,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}