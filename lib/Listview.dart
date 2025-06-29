import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'Database.dart';
import 'Widgets.dart';
import 'fulscreen.dart';

class MyListView extends StatefulWidget {
  final String title;
  final Stream<List<ImageModel>> stream;
  final Color backgroundColor;

  const MyListView({
    required this.title,
    required this.stream,
    required this.backgroundColor,
    super.key,
  });

  @override
  State<MyListView> createState() => _MyListViewState();
}

class _MyListViewState extends State<MyListView> {
  Future<void> _increaseViewCount(String id) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docRef = FirebaseFirestore.instance.collection('General').doc(id);
        final docSnapshot = await transaction.get(docRef);
        transaction.update(docRef, {
          'viewCount': (docSnapshot.get('viewCount') ?? 0) + 1,
        });
      });
    } catch (e) {
      print('Error updating view count: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMainSection = ['New', 'Hot', 'Trending', 'Favorites', 'Related'].contains(widget.title);
    final appBarTitle = isMainSection ? 'Poster' : widget.title;
    final subTitle = isMainSection ? 'Beautify your screen' : 'You are in ${widget.title} section';

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: appBarTitle != 'Poster'
          ? GradientAppBar(appBarTitle, 170, subTitle, true) as PreferredSizeWidget
          : null,
      body: StreamBuilder<List<ImageModel>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.amaranth(
                  textStyle: const TextStyle(color: Colors.black, fontSize: 15),
                ),
              ),
            );
          }

          final images = snapshot.data ?? [];
          if (images.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Noting Found Here.png',
                    fit: BoxFit.contain,
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Wallpapers',
                    style: GoogleFonts.amaranth(
                      textStyle: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 3,
                  childCount: images.length,
                  itemBuilder: (context, index) => _buildListItem(context, images[index]),
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ImageModel image) {
    final thumbnailUrl = image.thumbnailUrl;
    if (thumbnailUrl == null) {
      return _buildImageErrorWidget();
    }

    return InkWell(
      onTap: () async {
        try {
          final file = await DefaultCacheManager().getSingleFile(thumbnailUrl);
          _increaseViewCount(image.id);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreen(file, image),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load image: $e')),
            );
          }
        }
      },
      child: Hero(
        transitionOnUserGestures: true,
        tag: image.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CachedNetworkImage(
            imageUrl: thumbnailUrl,
            placeholder: (context, url) => Container(
              color: Colors.grey[300]!.withOpacity(0.4),
            ),
            errorWidget: (context, url, error) => _buildImageErrorWidget(),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() => Container(
    color: Colors.grey[200],
    child: Center(
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[400],
        size: 40,
      ),
    ),
  );
}