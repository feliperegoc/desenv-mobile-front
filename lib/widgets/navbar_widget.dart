import 'package:flutter/material.dart';

class NavbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;

  const NavbarWidget({
    Key? key,
    required this.isSidebarOpen,
    required this.toggleSidebar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue[800],
      leading: IconButton(
        icon: Icon(isSidebarOpen ? Icons.close : Icons.menu),
        onPressed: toggleSidebar,
        color: Colors.white,
      ),
      title: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcIn,
        ),
        child: Image.asset(
          'assets/logo_unifor.png',
          height: 40,
        ),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
