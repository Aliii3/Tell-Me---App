import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kAccent = Color(0xFF7C6FD4);

class HomeScreen extends StatelessWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  static const _dockRoutes = ['/home', '/home/tasks', '/home/calendar'];

  int _indexFromRoute(String location) {
    if (location == '/home') return 0;
    if (location.startsWith('/home/tasks')) return 1;
    if (location.startsWith('/home/calendar')) return 2;
    return -1; // chat / settings — no dock item active
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromRoute(location);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _NavDock(
              currentIndex: currentIndex,
              onTap: (i) => context.go(_dockRoutes[i]),
              onMic: () => context.go('/home/chat'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating dock ─────────────────────────────────────────────────────────────

class _NavDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onMic;

  const _NavDock({
    required this.currentIndex,
    required this.onTap,
    required this.onMic,
  });

  static const _icons = [
    Icons.home_rounded,
    Icons.format_list_bulleted_rounded,
    Icons.calendar_month_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Mic FAB ─────────────────────────────────────────────────────
            Semantics(
              button: true,
              label: 'Talk to Tell Me',
              child: GestureDetector(
              onTap: onMic,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccent.withValues(alpha: 0.82),
                  border: Border.all(
                    color: const Color(0xFFB4A8FF).withValues(alpha: 0.55),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withValues(alpha: 0.40),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: const Color(0xFFD2CAFF).withValues(alpha: 0.45),
                      blurRadius: 0,
                      spreadRadius: 0,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            ),

            const SizedBox(height: 10),

            // ── Dock pill ────────────────────────────────────────────────────
            IntrinsicWidth(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.60),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF504078).withValues(alpha: 0.09),
                      blurRadius: 28,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Semantics(
                      button: true,
                      selected: i == currentIndex,
                      label: const ['Home', 'Tasks', 'Calendar'][i],
                      child: _DockItem(
                        key: ValueKey(i),
                        icon: _icons[i],
                        active: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single dock item ──────────────────────────────────────────────────────────

class _DockItem extends StatefulWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _DockItem({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 54,
          height: 44,
          decoration: BoxDecoration(
            color: widget.active
                ? Colors.white.withValues(alpha: 0.38)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Icon
              Icon(
                widget.icon,
                size: 22,
                color: widget.active
                    ? const Color(0xFF4E3D8C)
                    : const Color(0xFF4E3D8C).withValues(alpha: 0.38),
              ),
              // Pip dot below icon when active
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                bottom: widget.active ? 4 : 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: widget.active ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C6FD4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
