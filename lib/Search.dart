import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Database.dart';
import 'fulscreen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Stream<List<ImageModel>>? _images;
  String? _keyword;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetSearch() {
    setState(() {
      _keyword = null;
      _images = null;
      _searchController.clear();
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _loadImages(String keyword) {
    setState(() {
      _keyword = keyword;
      _images = FirebaseFirestore.instance
          .collection('General')
          .where('tag', arrayContains: keyword.toLowerCase())
          .orderBy('uploadedTime', descending: true)
          .snapshots()
          .map(mapper);
    });
  }

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

  Future<void> _saveSearchSuggestion(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final suggestions = prefs.getStringList('suggestions_list') ?? [];
    if (suggestions.contains(value)) {
      suggestions.remove(value);
    }
    suggestions.insert(0, value);
    if (suggestions.length > 5) {
      suggestions.removeLast();
    }
    await prefs.setStringList('suggestions_list', suggestions);
  }

  Future<List<String>> _getSearchSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('suggestions_list') ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_keyword != null) {
          _resetSearch();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildSearchAppBar(),
        body: _keyword != null
            ? _buildSearchResults()
            : _buildSuggestions(),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (_keyword != null) {
            _resetSearch();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search wallpapers',
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        keyboardAppearance: Theme.of(context).brightness,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _saveSearchSuggestion(value.trim());
            _loadImages(value.trim());
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: _resetSearch,
        ),
      ],
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<ImageModel>>(
      stream: _images,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
                  'assets/Noting Found Here.png', // Aligned with Home.dart
                  fit: BoxFit.contain,
                  height: 150,
                  width: 150,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nothing Found...!!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.secondary,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w700,
                  ),
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
                itemBuilder: (context, index) => _buildListItem(context, images[index]),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return FutureBuilder<List<String>>(
      future: _getSearchSuggestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading suggestions',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          );
        }

        final suggestions = snapshot.data ?? [];
        if (suggestions.isEmpty) {
          return Center(
            child: Text(
              'No recent searches',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          );
        }

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
              ),
              title: Text(
                suggestions[index],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                ),
              ),
              onTap: () {
                _searchController.text = suggestions[index];
                _saveSearchSuggestion(suggestions[index]);
                _loadImages(suggestions[index]);
                FocusManager.instance.primaryFocus?.unfocus();
              },
            );
          },
        );
      },
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
          await _increaseViewCount(image.id);
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
          borderRadius: BorderRadius.circular(10),
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

  Widget _buildImageErrorWidget() {
    return Container(
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
}