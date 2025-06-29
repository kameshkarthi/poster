import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math' as math;

// Assuming Listview.dart contains the View widget
import 'Database.dart';
import 'Listview.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  StreamSubscription<QuerySnapshot>? subscription;
  List<DocumentSnapshot>? wallpapersList;
  final CollectionReference collectionReference =
  FirebaseFirestore.instance.collection("Category"); // Fixed typo

  @override
  void initState() {
    super.initState();
    // Initialize Firestore subscription
    subscription = collectionReference.snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          wallpapersList = snapshot.docs;
        });
      }
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI mode (replacing deprecated setEnabledSystemUIOverlays)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: wallpapersList != null && wallpapersList!.isNotEmpty
            ? GridView.count(
          padding: const EdgeInsets.all(8.0),
          crossAxisCount: 2, // Changed from 6 to 2 for uniform tiles
          childAspectRatio: 2 / 3, // Adjusted to match previous staggered sizes (2x3 or 2x4)
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          children: wallpapersList!.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            final imgPath = doc.get('categoryImage') as String?; // Renamed 'Cat' to 'categoryImage'
            final title = doc.get('title') as String?;
            if (imgPath == null || title == null) {
              return const SizedBox.shrink(); // Handle missing data
            }
            return Padding(
              padding: const EdgeInsets.all(4.0), // Reduced for tighter layout
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyListView(
                        title: title,
                        stream: FirebaseFirestore.instance
                            .collection('General')
                            .where('categoryId', isEqualTo: title)
                            .orderBy('uploadedTime', descending: true)
                            .snapshots()
                            .map(mapper),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0), // Reduced for better scaling
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imgPath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          color: Colors.black.withOpacity(0.5), // Semi-transparent background for text
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        )
            : const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}