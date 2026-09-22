import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../theme/app_typography.dart';
import '../../theme/aurora.dart';
import '../../widgets/neumorphic_card.dart';

const _bgTop    = Color(0xFFC5CCBF);
const _bgBottom = Color(0xFFBBB5AC);
const _accent   = Color(0xFF7C6FD4);
// Dark ink for text on the light sage background (white failed WCAG contrast).
const _ink      = Color(0xFF23261E);
const _inkSoft  = Color(0xFF565C4C);

const _dotColors = [
  Color(0xFF5DCAA5), // teal — low / done
  Color(0xFF7C6FD4), // purple — medium
  Color(0xFFE87A5A), // coral — high
];

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int _filter = 0; // 0=All, 1=To-do, 2=Done

  void _showAddTaskSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    String? selectedPriority; // null = no priority
    DateTime? selectedDueDate;
    TimeOfDay? selectedDueTime;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1E1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(children: [
                      Text('NEW TASK',
                          style: AppTypography.dotMatrix(
                              fontSize: 22, color: Colors.white, letterSpacing: 2)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, size: 18,
                              color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 22),

                    // Task title
                    const _SheetLabel(label: 'TASK TITLE'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'What needs to be done?',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.28)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: const Color(0xFF7C6FD4).withValues(alpha: 0.38), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF7C6FD4), width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    TextField(
                      controller: subtitleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Subtitle (optional)',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.28)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: const Color(0xFF7C6FD4).withValues(alpha: 0.60), width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Due date
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF7C6FD4),
                                surface: Color(0xFF1C1E1A),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setSheet(() => selectedDueDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedDueDate != null
                                ? const Color(0xFF7C6FD4).withValues(alpha: 0.50)
                                : Colors.white.withValues(alpha: 0.10),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 15,
                                color: selectedDueDate != null
                                    ? const Color(0xFF7C6FD4)
                                    : Colors.white.withValues(alpha: 0.30)),
                            const SizedBox(width: 10),
                            Text(
                              selectedDueDate != null
                                  ? DateFormat('EEE, MMM d').format(selectedDueDate!)
                                  : 'Due date (optional)',
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedDueDate != null
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : Colors.white.withValues(alpha: 0.28),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (selectedDueDate != null) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setSheet(() {
                                  selectedDueDate = null;
                                  selectedDueTime = null;
                                }),
                                child: Icon(Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.35)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Due time (only meaningful with a date)
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedDueTime ?? TimeOfDay.now(),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF7C6FD4),
                                surface: Color(0xFF1C1E1A),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setSheet(() {
                            selectedDueTime = picked;
                            selectedDueDate ??= DateTime.now();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedDueTime != null
                                ? const Color(0xFF7C6FD4).withValues(alpha: 0.50)
                                : Colors.white.withValues(alpha: 0.10),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 15,
                                color: selectedDueTime != null
                                    ? const Color(0xFF7C6FD4)
                                    : Colors.white.withValues(alpha: 0.30)),
                            const SizedBox(width: 10),
                            Text(
                              selectedDueTime != null
                                  ? selectedDueTime!.format(ctx)
                                  : 'Reminder time (optional)',
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedDueTime != null
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : Colors.white.withValues(alpha: 0.28),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (selectedDueTime != null) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    setSheet(() => selectedDueTime = null),
                                child: Icon(Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.35)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Priority
                    const _SheetLabel(label: 'PRIORITY'),
                    const SizedBox(height: 10),
                    Row(children: [
                      _PriorityBtn(
                        label: 'Low', bg: const Color(0xFF1E3520), fg: const Color(0xFF5DB85D),
                        active: selectedPriority == 'Low',
                        onTap: () => setSheet(() => selectedPriority =
                            selectedPriority == 'Low' ? null : 'Low'),
                      ),
                      const SizedBox(width: 8),
                      _PriorityBtn(
                        label: 'Medium', bg: const Color(0xFF252038), fg: const Color(0xFFB9A6FF),
                        active: selectedPriority == 'Medium',
                        onTap: () => setSheet(() => selectedPriority =
                            selectedPriority == 'Medium' ? null : 'Medium'),
                      ),
                      const SizedBox(width: 8),
                      _PriorityBtn(
                        label: 'High', bg: const Color(0xFF321A1A), fg: const Color(0xFFE07070),
                        active: selectedPriority == 'High',
                        onTap: () => setSheet(() => selectedPriority =
                            selectedPriority == 'High' ? null : 'High'),
                      ),
                    ]),

                    const SizedBox(height: 26),

                    // CTA
                    GestureDetector(
                      onTap: () {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) return;
                        final priority = switch (selectedPriority) {
                          'High' => TaskPriority.high,
                          'Medium' => TaskPriority.medium,
                          'Low' => TaskPriority.low,
                          _ => TaskPriority.none,
                        };
                        final dueTime = selectedDueTime != null
                            ? DateFormat('h:mm a').format(DateTime(
                                2000, 1, 1,
                                selectedDueTime!.hour, selectedDueTime!.minute))
                            : null;
                        ref.read(tasksProvider.notifier).addTask(
                              title,
                              subtitle: subtitleCtrl.text.trim().isEmpty ? null : subtitleCtrl.text.trim(),
                              priority: priority,
                              dueDate: selectedDueDate,
                              dueTime: dueTime,
                            );
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: double.infinity, height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C6FD4),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C6FD4).withValues(alpha: 0.35),
                              blurRadius: 20, offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text('Create task →',
                              style: AppTypography.bodyLg(color: Colors.white, weight: FontWeight.w700)
                                  .copyWith(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(tasksProvider);
    final tasks = _filter == 1
        ? all.where((t) => !t.isDone).toList()
        : _filter == 2
            ? all.where((t) => t.isDone).toList()
            : all;

    return Scaffold(
      backgroundColor: _bgTop,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  // ── Top bar ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          const _StarBurst(),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showAddTaskSheet(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _ink.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Title ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Text(
                            'Tasks',
                            style: AppTypography.displayLg(color: _ink)
                                .copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),

                  // ── Filter pills ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                      child: Row(
                        children: [
                          for (final (i, label) in [
                            'All',
                            'To-do',
                            'Done'
                          ].indexed)
                            GestureDetector(
                              onTap: () => setState(() => _filter = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _filter == i
                                      ? Colors.white.withValues(alpha: 0.92)
                                      : Colors.white.withValues(alpha: 0.32),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _filter == i
                                        ? const Color(0xFF2A2A2A)
                                        : _ink.withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Task list ─────────────────────────────────────────
                  if (tasks.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _ink.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 26,
                                color: _ink.withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No tasks yet',
                              style: AppTypography.bodyMd(
                                color: _ink,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap + to add a task, or hit the mic and just say it',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption(
                                color: _inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final t = tasks[i];
                          final dot = t.isDone
                              ? _dotColors[0]
                              : switch (t.priority) {
                                  TaskPriority.high => _dotColors[2],
                                  TaskPriority.medium => _dotColors[1],
                                  TaskPriority.low => _dotColors[0],
                                  TaskPriority.none =>
                                    Colors.white.withValues(alpha: 0.30),
                                };
                          return Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              final removed = t;
                              ref
                                  .read(tasksProvider.notifier)
                                  .deleteTask(removed.id);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('Deleted "${removed.title}"'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 4),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () => ref
                                          .read(tasksProvider.notifier)
                                          .restoreTask(removed),
                                    ),
                                  ),
                                );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 7),
                              padding: const EdgeInsets.only(right: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB33F38),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  size: 20, color: Colors.white),
                            ),
                            child: _TaskRow(
                              title: t.title,
                              subtitle: t.subtitle ?? '',
                              done: t.isDone,
                              dotColor: dot,
                              onTap: () => context.go('/task/${t.id}'),
                              onToggle: () => ref
                                  .read(tasksProvider.notifier)
                                  .toggleDone(t.id),
                            ),
                          );
                        },
                        childCount: tasks.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 150)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task row ──────────────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final Color dotColor;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _TaskRow({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.dotColor,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicCard(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        baseColor: _bgBottom,
        borderRadius: 15,
        child: Row(
          children: [
            // Checkbox — tap toggles done, doesn't navigate. The visible dot
            // is small but the tap target is a full 44pt.
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? _accent : Colors.transparent,
                      border: done
                          ? null
                          : Border.all(
                              color: _ink.withValues(alpha: 0.45),
                              width: 1.5),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 13, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySm(
                      color: _ink,
                      weight: FontWeight.w600,
                    ).copyWith(
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.micro(color: _inkSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Priority dot
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Star burst ────────────────────────────────────────────────────────────────

class _StarBurst extends StatelessWidget {
  const _StarBurst();

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 24, height: 24, child: CustomPaint(painter: _StarPainter()));
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _ink.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.42;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
          Offset(cx, cy), Offset(cx + r * math.cos(a), cy + r * math.sin(a)), p);
    }
  }

  @override
  bool shouldRepaint(_StarPainter _) => false;
}

// ── Sheet label ───────────────────────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String label;
  const _SheetLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.55),
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Priority button ───────────────────────────────────────────────────────────

class _PriorityBtn extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final bool active;
  final VoidCallback onTap;

  const _PriorityBtn({
    required this.label,
    required this.bg,
    required this.fg,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: fg.withValues(alpha: active ? 0.40 : 0.18),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: active ? 1.0 : 0.70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
