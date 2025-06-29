import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Database.dart';
import 'Listview.dart';

// ignore: must_be_immutable
class Random extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    String str = 'Trending';
    return MyListView(
        title: str,
        stream: FirebaseFirestore.instance
            .collection('General')
            .orderBy('viewCount', descending: true)
            .snapshots()
            .map(mapper),
        backgroundColor:  Theme.of(context).primaryColor);
  }
}
