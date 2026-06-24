import 'package:flutter/material.dart';

class MyKeywordScreen extends StatefulWidget {
  const MyKeywordScreen({super.key});

  @override
  State<MyKeywordScreen> createState() => _MyKeywordScreenState();
}

class _MyKeywordScreenState extends State<MyKeywordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff171717),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,

        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '발견'),

          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: '지도',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: '스크랩',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '프로필',
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 20),

              /// Header
              Row(
                children: [
                  const Text(
                    '내취향',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Text(
                    '전체',

                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  Spacer(),

                  Icon(Icons.search, color: Colors.white),
                ],
              ),

              const SizedBox(height: 20),

              /// chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                child: Row(
                  children: [
                    chip('무료', true),

                    chip('이번주', false),

                    chip('예약없이', false),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// poster
              ClipRRect(
                borderRadius: BorderRadius.circular(12),

                child: Container(
                  height: 320,

                  width: double.infinity,

                  color: Colors.amber,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '문화역서울 284 내부 공간투어',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 20,

                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 4),

              Text(
                '문화역서울 284 · 26.04.10~26.04.31',

                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chip(String text, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),

      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),

          color: selected ? Colors.limeAccent : Color(0xff2B2B2B),
        ),

        child: Text(
          text,

          style: TextStyle(
            color: selected ? Colors.black : Colors.white,

            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
