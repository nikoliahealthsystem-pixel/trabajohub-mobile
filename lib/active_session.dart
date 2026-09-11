import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/constants/app_constants.dart';
import 'features/auth/presentation/profile_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/messaging/presentation/conversations_screen.dart';
import 'features/messaging/presentation/widgets/messaging_icon.dart';
import 'features/shifts/presentation/my_shifts_screen.dart';
import 'features/visits/presentation/visits_screen.dart';

class ActiveSession extends StatefulWidget {
  final int pageIndex;

  const ActiveSession({super.key, this.pageIndex = 0});

  @override
  State<ActiveSession> createState() => _ActiveSessionState();
}

class _ActiveSessionState extends State<ActiveSession> {
  int _pageIndex = 0;

  static const Color _inactiveColor = Color(0xFF98A2B3);
  static const Color _labelColor = Color(0xFF475467);
  static const Color _borderColor = Color(0xFFE4E7EC);

  @override
  void initState() {
    super.initState();

    if (widget.pageIndex >= 0 && widget.pageIndex <= 4) {
      _pageIndex = widget.pageIndex;
    }
  }

  void _selectPage(int index) {
    if (_pageIndex == index) return;

    setState(() {
      _pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(),
      MyShiftsScreen(),
      VisitsScreen(),
      ConversationsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      body: IndexedStack(index: _pageIndex, children: pages),

      bottomNavigationBar: _PremiumBottomBar(
        currentIndex: _pageIndex,
        onChanged: _selectPage,
      ),
    );
  }
}

class _PremiumBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _PremiumBottomBar({
    required this.currentIndex,
    required this.onChanged,
  });

  static const Color _inactiveColor = Color(0xFF98A2B3);
  static const Color _labelColor = Color(0xFF475467);
  static const Color _borderColor = Color(0xFFE4E7EC);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12101828),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    index: 0,
                    currentIndex: currentIndex,
                    label: 'Home',
                    iconPath: 'svg/home.svg',
                    onTap: onChanged,
                  ),
                ),

                Expanded(
                  child: _NavItem(
                    index: 1,
                    currentIndex: currentIndex,
                    label: 'Shifts',
                    iconPath: 'svg/list.svg',
                    onTap: onChanged,
                  ),
                ),

                Expanded(
                  child: _NavItem(
                    index: 2,
                    currentIndex: currentIndex,
                    label: 'Visits',
                    iconPath: 'svg/calender.svg',
                    onTap: onChanged,
                  ),
                ),

                Expanded(
                  child: _NavItem(
                    index: 3,
                    currentIndex: currentIndex,
                    label: 'Messages',
                    iconPath: 'svg/message.svg',
                    messaging: true,
                    onTap: onChanged,
                  ),
                ),

                Expanded(
                  child: _NavItem(
                    index: 4,
                    currentIndex: currentIndex,
                    label: 'Profile',
                    iconPath: 'svg/profile.svg',
                    onTap: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String label;
  final String iconPath;
  final bool messaging;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.iconPath,
    required this.onTap,
    this.messaging = false,
  });

  static const Color _inactiveColor = Color(0xFF98A2B3);
  static const Color _labelColor = Color(0xFF475467);

  @override
  Widget build(BuildContext context) {
    final selected = currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? accentColor.withOpacity(.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 38 : 34,
                height: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accentColor.withOpacity(.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: messaging
                    ? MessagingIconButton(
                        iconColor: selected ? Colors.white : _inactiveColor,
                        iconPath: iconPath,
                      )
                    : SvgPicture.asset(
                        'assets/$iconPath',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          selected ? Colors.white : _inactiveColor,
                          BlendMode.srcIn,
                        ),
                      ),
              ),

              const SizedBox(height: 4),

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? accentColor : _labelColor,
                  fontSize: 10.5,
                  height: 1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 18 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: selected ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
