import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Database.dart';
import 'Listview.dart';

class New extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    String str = 'New';
    return MyListView(
        title: str,
        stream: FirebaseFirestore.instance
            .collection('General')
            .orderBy('uploadedTime', descending: true)
            .snapshots()
            .map(mapper),
        backgroundColor:  Theme.of(context).primaryColor);
  }
}
