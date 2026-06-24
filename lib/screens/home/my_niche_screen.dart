import 'package:flutter/material.dart';
import 'package:muntum/screens/home/components/pageHeader.dart';

class MyNicheScreen extends StatefulWidget {
  const MyNicheScreen({super.key});

  @override
  State<MyNicheScreen> createState() => _MyNicheScreenState();
}

class _MyNicheScreenState extends State<MyNicheScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              HeaderTabItem(text: '내취향', textColor: TabTextColor.black),
            ],
          ),
        ],
      ),
    );
  }
}
