import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'Database.dart';
import 'fulscreen.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage();

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<List<ImageModel>>(
        future: ImageDB().fetchFavorites(orderBy: ImageDB.createdAtDesc),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final images = snapshot.data ?? [];
          if (images.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Noting Found Here.png', // Ensure this is in pubspec.yaml
                    fit: BoxFit.cover,
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nothing Found Here...!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 3,
                  childCount: images.length,
                  itemBuilder: (context, index) => _listItem(context, images[index]),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _listItem(BuildContext context, ImageModel image) {
    final thumbnailUrl = image.thumbnailUrl;
    if (thumbnailUrl == null) {
      return _buildImageErrorWidget();
    }

    return InkWell(
      onTap: () async {
        try {
          final file = await DefaultCacheManager().getSingleFile(thumbnailUrl);
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
        tag: image.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: CachedNetworkImage(
            imageUrl: thumbnailUrl,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
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