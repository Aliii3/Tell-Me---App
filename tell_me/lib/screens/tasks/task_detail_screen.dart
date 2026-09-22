import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/tasks_provider.dart';
import '../../models/task.dart';
import '../../theme/app_typography.dart';
import '../../theme/aurora.dart';

const _bgTop    = Color(0xFFC5CCBF);
const _accent   = Color(0xFF7C6FD4);

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  static TimeOfDay? _timeOfDay(String? display) {
    if (display == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$')
        .firstMatch(display.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Task task) {
    final titleCtrl    = TextEditingController(text: task.title);
    final subtitleCtrl = TextEditingController(text: task.subtitle ?? '');
    DateTime? dueDate  = task.dueDate;
    TimeOfDay? dueTime = _timeOfDay(task.dueTime);
    var priority       = task.priority;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1E1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(children: [
                    Text('EDIT TASK',
                        style: AppTypography.dotMatrix(fontSize: 20, color: Colors.white, letterSpacing: 2)),
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
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.28)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _accent.withValues(alpha: 0.38), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                        borderSide: BorderSide(color: _accent.withValues(alpha: 0.60), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _PickerChip(
                        icon: Icons.calendar_today_outlined,
                        label: dueDate != null
                            ? DateFormat('EEE, MMM d').format(dueDate!)
                            : 'Due date',
                        active: dueDate != null,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 5)),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: _accent,
                                  surface: Color(0xFF1C1E1A),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheet(() => dueDate = picked);
                          }
                        },
                        onClear: dueDate != null
                            ? () => setSheet(() {
                                  dueDate = null;
                                  dueTime = null;
                                })
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PickerChip(
                        icon: Icons.schedule_rounded,
                        label: dueTime != null
                            ? dueTime!.format(ctx)
                            : 'Time',
                        active: dueTime != null,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: dueTime ?? TimeOfDay.now(),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: _accent,
                                  surface: Color(0xFF1C1E1A),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheet(() {
                              dueTime = picked;
                              dueDate ??= DateTime.now();
                            });
                          }
                        },
                        onClear: dueTime != null
                            ? () => setSheet(() => dueTime = null)
                            : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    for (final p in const [
                      (TaskPriority.low, 'Low', Color(0xFF1E3520), Color(0xFF5DB85D)),
                      (TaskPriority.medium, 'Medium', Color(0xFF252038), Color(0xFFB9A6FF)),
                      (TaskPriority.high, 'High', Color(0xFF321A1A), Color(0xFFE07070)),
                    ]) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheet(() => priority =
                              priority == p.$1 ? TaskPriority.none : p.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 36,
                            decoration: BoxDecoration(
                              color: p.$3,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: p.$4.withValues(
                                    alpha: priority == p.$1 ? 0.40 : 0.18),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                p.$2,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: p.$4.withValues(
                                      alpha: priority == p.$1 ? 1.0 : 0.70),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (p.$1 != TaskPriority.high) const SizedBox(width: 8),
                    ],
                  ]),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: () {
                      final t = titleCtrl.text.trim();
                      if (t.isEmpty) return;
                      final sub = subtitleCtrl.text.trim();
                      final timeLabel = dueTime != null
                          ? DateFormat('h:mm a').format(DateTime(
                              2000, 1, 1, dueTime!.hour, dueTime!.minute))
                          : null;
                      ref.read(tasksProvider.notifier).updateTask(
                            task.copyWith(
                              title: t,
                              subtitle: sub.isEmpty ? null : sub,
                              clearSubtitle: sub.isEmpty,
                              dueDate: dueDate,
                              clearDueDate: dueDate == null,
                              dueTime: timeLabel,
                              clearDueTime: timeLabel == null,
                              priority: priority,
                            ),
                          );
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity, height: 54,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Center(
                        child: Text('Save changes →',
                            style: AppTypography.bodyLg(color: Colors.white, weight: FontWeight.w700)
                                .copyWith(fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete task?',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: Text(
          '"${task.title}" will be removed everywhere. This can\'t be undone.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.70))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE07070))),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(tasksProvider.notifier).deleteTask(task.id);
      if (context.mounted) context.go('/home/tasks');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final task = tasks.where((t) => t.id == taskId).firstOrNull;

    return Scaffold(
      backgroundColor: _bgTop,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/home/tasks'),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30), width: 1),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 14, color: Aurora.ink.withValues(alpha: 0.75)),
                        ),
                      ),
                      const Spacer(),
                      if (task != null) ...[
                        GestureDetector(
                          onTap: () => _confirmDelete(context, ref, task),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30), width: 1),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: Color(0xFFE07070)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showEditSheet(context, ref, task),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30), width: 1),
                            ),
                            child: Icon(Icons.edit_outlined,
                                size: 15, color: Aurora.ink.withValues(alpha: 0.75)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (task == null) ...[
                  const Spacer(),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Task not found',
                          style: TextStyle(
                              color: Aurora.ink.withValues(alpha: 0.65),
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.go('/home/tasks'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text('Back to tasks',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ] else ...[
                  const SizedBox(height: 24),

                  // ── Task card ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.42),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.60),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status dot + done state
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: task.isDone
                                      ? const Color(0xFF5DCAA5)
                                      : _accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                task.isDone ? 'Completed' : task.status.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Aurora.inkSoft.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            task.title,
                            style: AppTypography.displayLg(color: Aurora.ink)
                                .copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (task.subtitle != null) ...[
                            const SizedBox(height: 6),
                            HighlightText(
                              task.subtitle!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                          if (task.dueDate != null ||
                              task.category != null ||
                              task.priority != TaskPriority.none) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (task.dueDate != null)
                                  _Badge(
                                    label: task.dueTime != null
                                        ? '${DateFormat('EEE, MMM d').format(task.dueDate!)} · ${task.dueTime}'
                                        : DateFormat('EEE, MMM d')
                                            .format(task.dueDate!),
                                    color: const Color(0xFF5DCAA5),
                                  ),
                                if (task.category != null)
                                  _Badge(label: task.category!, color: _accent),
                                if (task.priority != TaskPriority.none)
                                  _Badge(
                                    label: '${task.priority.name} priority',
                                    color: const Color(0xFFE87A5A),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Action button ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(tasksProvider.notifier).toggleDone(task.id),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: task.isDone
                              ? Colors.white.withValues(alpha: 0.40)
                              : _accent,
                          borderRadius: BorderRadius.circular(100),
                          border: task.isDone
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.60),
                                  width: 1)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          task.isDone ? 'Mark as Incomplete' : 'Mark as Complete',
                          style: TextStyle(
                            color: task.isDone ? Aurora.ink : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? _accent.withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: active
                    ? _accent
                    : Colors.white.withValues(alpha: 0.30)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: active
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.28),
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Icon(Icons.close_rounded,
                    size: 13, color: Colors.white.withValues(alpha: 0.35)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.80),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
