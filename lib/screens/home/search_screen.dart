import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/screens/home/components/appbar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            onLeadingTap: () {
              Navigator.pop(context);
            },
            leadingIcon: "arrow_left.svg",
            centerType: AppBarCenterType.searchbar,
          ),
        ],
      ),
    );
  }
}
