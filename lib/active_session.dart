import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trabajo_hub/features/auth/presentation/profile_screen.dart';
import 'package:trabajo_hub/features/dashboard/presentation/dashboard_screen.dart';
import 'package:trabajo_hub/features/messaging/presentation/conversations_screen.dart';
import 'package:trabajo_hub/features/shifts/presentation/my_shifts_screen.dart';
import 'package:trabajo_hub/features/visits/presentation/visits_screen.dart';

import 'core/constants/app_constants.dart';
import 'features/messaging/presentation/widgets/messaging_icon.dart';
import 'features/shifts/presentation/marketplace_screen.dart';


class ActiveSession extends StatefulWidget {
  final int pageIndex;

  const ActiveSession({super.key, this.pageIndex = 0});

  @override
  State<ActiveSession> createState() => _ActiveSessionState();
}

class _ActiveSessionState extends State<ActiveSession> {
  int _pageIndex = 0;
  @override
  void initState() {
    super.initState();
    _pageIndex = widget.pageIndex;
  }

  // Function to handle BottomNavigationBar item taps
  void _bottomNavTapped(int index) {
    setState(() {
      _pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pages to display for each BottomNavigationBarItem
    final List<Widget> selectedPage = [
      DashboardScreen(),
      MyShiftsScreen(),
      VisitsScreen(),
      ConversationsScreen(),
      ProfileScreen()
    ];

    return Scaffold(
      body: SafeArea(
          top: false,
          child: selectedPage[_pageIndex]), // Display the selected page
      bottomNavigationBar:
          //_buildBottomBar(),
          BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 243, 243, 243),
        type: BottomNavigationBarType.fixed,
        onTap: _bottomNavTapped,
        currentIndex: _pageIndex,
        selectedItemColor: accentColor,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        items: [
          _buildBottomNavItem('svg/home.svg', 'Dashboard', 0),
          _buildBottomNavItem('svg/list.svg', 'My Shifts', 1),
          _buildBottomNavItem('svg/calender.svg', 'My Visits', 2),
          _buildBottomNavItem('svg/message.svg', 'Messaging', 3),
          _buildBottomNavItem('svg/profile.svg', 'Profile', 4),
        ],
      ),
    );
  }

  // Function to build each BottomNavigationBarItem
  BottomNavigationBarItem _buildBottomNavItem(
      String iconPath, String label, int index) {
    return BottomNavigationBarItem(
      icon: (label =="Messaging") ?
      MessagingIconButton(iconColor: _pageIndex == index ? accentColor : Colors.grey, iconPath: iconPath,) : SvgPicture.asset(
        'assets/$iconPath',
        width: 28,
        height: 28,
        color: _pageIndex == index ? accentColor : Colors.grey,
      ),
      label: label, // Dynamic label
    );
  }
}
