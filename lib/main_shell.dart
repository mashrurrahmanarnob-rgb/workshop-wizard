import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/proposals_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/president_home_screen.dart';
import 'screens/committee_home_screen.dart';
import 'screens/treasurer_home_screen.dart';
import 'screens/role_management_screen.dart';
import 'screens/submit_feedback_screen.dart';
import 'screens/feedback_list_screen.dart';
import 'widgets/bottom_nav_bar.dart';

class _TabConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const _TabConfig({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}

class MainShell extends StatefulWidget {
  final String role;
  final String email;

  const MainShell({super.key, required this.role, required this.email});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final List<_TabConfig> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = _buildTabs(widget.role, widget.email);
    _currentIndex = _homeTabIndex(_tabs);
  }

  List<_TabConfig> _buildTabs(String role, String email) {
    final profileTab = _TabConfig(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      screen: ProfileScreen(role: role, email: email),
    );

    switch (role.toLowerCase()) {

      case 'student':
        return [
          _TabConfig(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            screen: StudentHomeScreen(email: email),
          ),
          _TabConfig(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Feedback',
            screen: SubmitFeedbackScreen(email: email),
          ),
          profileTab,
        ];

      case 'president':
        return [
          _TabConfig(
            icon: Icons.description_outlined,
            activeIcon: Icons.description,
            label: 'Proposals',
            screen: PresidentProposalsScreen(role: role),
          ),
          _TabConfig(
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum,
            label: 'Feedback',
            screen: const FeedbackListScreen(),
          ),
          _TabConfig(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            screen: PresidentHomeScreen(email: email),
          ),
          _TabConfig(
            icon: Icons.manage_accounts_outlined,
            activeIcon: Icons.manage_accounts,
            label: 'Users',
            screen: const RoleManagementScreen(),
          ),
          profileTab,
        ];

      case 'committee':
        return [
          _TabConfig(
            icon: Icons.description_outlined,
            activeIcon: Icons.description,
            label: 'Proposals',
            screen: ProposalsScreen(role: role),
          ),
          _TabConfig(
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum,
            label: 'Feedback',
            screen: const FeedbackListScreen(),
          ),
          _TabConfig(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            screen: CommitteeHomeScreen(email: email),
          ),
          profileTab,
        ];

      case 'treasurer':
        return [
          _TabConfig(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            screen: TreasurerHomeScreen(email: email),
          ),
          _TabConfig(
            icon: Icons.credit_card_outlined,
            activeIcon: Icons.credit_card,
            label: 'Payments',
            screen: PaymentsScreen(role: role),
          ),
          profileTab,
        ];

      default:
        return [
          _TabConfig(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            screen: HomeScreen(role: role, email: email),
          ),
          profileTab,
        ];
    }
  }

  int _homeTabIndex(List<_TabConfig> tabs) {
    final i = tabs.indexWhere((t) => t.label == 'Home');
    return i >= 0 ? i : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        tabs: _tabs
            .map((t) => NavTabItem(
          icon: t.icon,
          activeIcon: t.activeIcon,
          label: t.label,
        ))
            .toList(),
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
