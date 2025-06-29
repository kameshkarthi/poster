import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Database.dart';
import 'Listview.dart';

// ignore: must_be_immutable
class Hot extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    String str = 'Hot';
    return MyListView(
        title: str,
        stream: FirebaseFirestore
            .instance
            .collection('General')
            .orderBy('uploadedTime', descending: true)
            .where('paid', isEqualTo: 1)
            .snapshots()
            .map(mapper),
        backgroundColor:  Theme.of(context).primaryColor
    );
  }

}