import 'package:flutter/material.dart';
import 'package:kinton_driver/ui/menu/home_page.dart';
import 'package:kinton_driver/ui/menu/income_page.dart';


import 'menu/profile_page.dart';

class LayoutNavigationBar extends StatefulWidget {


  String accessToken;

  LayoutNavigationBar({super.key, required this.accessToken});

  @override
  State<LayoutNavigationBar> createState() => _LayoutNavigationBarState();
}

class _LayoutNavigationBarState extends State<LayoutNavigationBar> {
  int _currentIndex = 0;

  late final List<Widget> _children;

  @override
  void initState() {
    super.initState();

    _children = [
      HomePage(
        accesstoken: widget.accessToken,
      ),
       IncomePage(accesstoken: widget.accessToken),
      ProfilePage(accesstoken: widget.accessToken,),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onBarTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.trending_up), label: 'Pendapatan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  void onBarTapped(int value) {
    setState(() {
      _currentIndex = value;
    });
  }
}
