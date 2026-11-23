import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool showAppBar;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.showAppBar = true,
    this.showBackButton = false,
    this.onBackTap,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    bool showVolcanoStatusBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                      onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
                    )
                  : null,
              title: title != null
                  ? Text(
                      title!,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'lib/img/logo.png',
                            width: 26,
                            height: 26,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MerapiTrip',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
              actions: actions ??
                  [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
                      onPressed: () {
                        // Dapat dinavigasikan ke Layar Notifikasi
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
            )
          : null,
      body: SafeArea(
        top: !showAppBar,
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
