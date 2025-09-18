
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';

class KanjadAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const KanjadAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/kanjad.png',
            key: const ValueKey('logo'),
            width: 140,
            height: 50,
          ),
          if (subtitle != null)
            Transform.translate(
              offset: const Offset(-20, 12),
              child: Text(
                subtitle!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Styles.rouge,
      foregroundColor: Styles.blanc,
      centerTitle: true,
      elevation: 0,
      shape: const RoundedRectangleBorder(
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
