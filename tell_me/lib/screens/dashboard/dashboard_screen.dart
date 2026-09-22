import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/project.dart';
import '../../providers/auth_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../theme/app_typography.dart';
import '../../theme/aurora.dart';
import '../../theme/grain_painter.dart';
import '../../widgets/neumorphic_card.dart';

const _uuid = Uuid();

// ── Design tokens ─────────────────────────────────────────────────────────────
const _bgTop    = Color(0xFFC5CCBF);
const _bgBottom = Color(0xFFBBB5AC);
const _darkCard = Color(0xFF1A1D18);
const _darkCard2= Color(0xFF252920);
const _chipActive   = Colors.white;
const _accent   = Color(0xFF7C6FD4);
const _checkFill    = Color(0xFF7C6FD4);
// Dark ink for text on the light sage background (white failed WCAG contrast).
const _ink      = Color(0xFF23261E);
const _inkSoft  = Color(0xFF565C4C);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _filterIndex = 0;
  static const _filters = ['All plans', 'Ongoing', 'Future'];

  Future<void> _showNewProjectSheet() async {
    final titleController = TextEditingController();
    var selectedEmoji = '📝';
    var selectedType  = 'Ongoing';
    String? selectedPriority;
    DateTime? selectedDueDate;
    final user = ref.read(authStateProvider).valueOrNull;
    final creatorName =
        _firstName(user?.displayName ?? user?.email?.split('@').first ?? 'Me');

    const emojis = ['📝', '🎯', '💼', '🚀', '💡'];

    ProjectStatus typeToStatus(String t) {
      if (t == 'Future') return ProjectStatus.future;
      return ProjectStatus.ongoing;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
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
                    // ── Drag handle ────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── Header ─────────────────────────────────────────────
                    Row(
                      children: [
                        Text(
                          'NEW PLAN',
                          style: AppTypography.dotMatrix(
                            fontSize: 22,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ── Plan title ─────────────────────────────────────────
                    const _SheetLabel(label: 'PLAN TITLE'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write proposal for Inc.',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: const Color(0xFF7C6FD4).withValues(alpha: 0.38),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C6FD4),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Due date ───────────────────────────────────────────
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
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
                        if (picked != null) {
                          setSheet(() => selectedDueDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'DUE DATE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.38),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  selectedDueDate != null
                                      ? DateFormat('MMM d, yyyy').format(selectedDueDate!)
                                      : 'Pick a date...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedDueDate != null
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : Colors.white.withValues(alpha: 0.22),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: selectedDueDate != null
                                  ? const Color(0xFF7C6FD4)
                                  : Colors.white.withValues(alpha: 0.22),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Emoji picker ───────────────────────────────────────
                    const _SheetLabel(label: 'PICK AN EMOJI'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ...emojis.map((e) {
                          final active = selectedEmoji == e;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setSheet(() => selectedEmoji = e),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(right: 8),
                                height: 52,
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFF7C6FD4)
                                          .withValues(alpha: 0.28)
                                      : Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(14),
                                  border: active
                                      ? Border.all(
                                          color: const Color(0xFF7C6FD4)
                                              .withValues(alpha: 0.55),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Text(e,
                                      style:
                                          const TextStyle(fontSize: 22)),
                                ),
                              ),
                            ),
                          );
                        }),
                        // Dashed "more" slot
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '···',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 14,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ── Type ───────────────────────────────────────────────
                    const _SheetLabel(label: 'TYPE'),
                    const SizedBox(height: 10),
                    Row(
                      children: ['Ongoing', 'One-time', 'Future']
                          .map((t) {
                        final active = selectedType == t;
                        return GestureDetector(
                          onTap: () => setSheet(() => selectedType = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF3D3568)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.50),
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 22),

                    // ── Priority ───────────────────────────────────────────
                    const _SheetLabel(label: 'PRIORITY'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _PriorityBtn(
                          label: 'Low',
                          bg: const Color(0xFF1E3520),
                          fg: const Color(0xFF5DB85D),
                          active: selectedPriority == 'Low',
                          onTap: () => setSheet(() => selectedPriority =
                              selectedPriority == 'Low' ? null : 'Low'),
                        ),
                        const SizedBox(width: 8),
                        _PriorityBtn(
                          label: 'Medium',
                          bg: const Color(0xFF252038),
                          fg: const Color(0xFFB9A6FF),
                          active: selectedPriority == 'Medium',
                          onTap: () => setSheet(() => selectedPriority =
                              selectedPriority == 'Medium' ? null : 'Medium'),
                        ),
                        const SizedBox(width: 8),
                        _PriorityBtn(
                          label: 'High',
                          bg: const Color(0xFF321A1A),
                          fg: const Color(0xFFE07070),
                          active: selectedPriority == 'High',
                          onTap: () => setSheet(() => selectedPriority =
                              selectedPriority == 'High' ? null : 'High'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // ── CTA ────────────────────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;
                        ref.read(projectsProvider.notifier).addProject(
                              Project(
                                id: _uuid.v4(),
                                title: title,
                                emoji: selectedEmoji,
                                status: typeToStatus(selectedType),
                                createdBy: creatorName,
                                progress: 0.0,
                                colorValue: Colors.white.toARGB32(),
                                createdAt: DateTime.now(),
                                dueDate: selectedDueDate,
                                priorityIndex: _priorityIndex(selectedPriority),
                              ),
                            );
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C6FD4),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C6FD4)
                                  .withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Create plan →',
                            style: AppTypography.bodyLg(
                              color: Colors.white,
                              weight: FontWeight.w700,
                            ).copyWith(fontSize: 16),
                          ),
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
    titleController.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  Future<void> _showEditProjectSheet(Project project) async {
    final titleCtrl = TextEditingController(text: project.title);
    var selectedEmoji = project.emoji;
    var selectedType = project.status == ProjectStatus.future ? 'Future' : 'Ongoing';

    const emojis = ['📝', '🎯', '💼', '🚀', '💡'];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF1C1E1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                    Text('EDIT PLAN',
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
                  const _SheetLabel(label: 'PLAN TITLE'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Plan title',
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
                  const SizedBox(height: 22),
                  const _SheetLabel(label: 'PICK AN EMOJI'),
                  const SizedBox(height: 10),
                  Row(
                    children: emojis.map((e) {
                      final active = selectedEmoji == e;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheet(() => selectedEmoji = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            height: 52,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF7C6FD4).withValues(alpha: 0.28)
                                  : Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                              border: active
                                  ? Border.all(color: const Color(0xFF7C6FD4).withValues(alpha: 0.55), width: 1)
                                  : null,
                            ),
                            child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  const _SheetLabel(label: 'TYPE'),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Ongoing', 'Future'].map((t) {
                      final active = selectedType == t;
                      return GestureDetector(
                        onTap: () => setSheet(() => selectedType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF3D3568) : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                color: active ? Colors.white : Colors.white.withValues(alpha: 0.50),
                                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 13,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 26),
                  GestureDetector(
                    onTap: () {
                      final t = titleCtrl.text.trim();
                      if (t.isEmpty) return;
                      ref.read(projectsProvider.notifier).updateProject(
                            project.copyWith(
                              title: t,
                              emoji: selectedEmoji,
                              status: selectedType == 'Future'
                                  ? ProjectStatus.future
                                  : ProjectStatus.ongoing,
                            ),
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
                        child: Text('Save changes →',
                            style: AppTypography.bodyLg(color: Colors.white, weight: FontWeight.w700)
                                .copyWith(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    titleCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProjects = ref.watch(projectsProvider);
    final projects = _filterIndex == 1
        ? allProjects.where((p) => p.status == ProjectStatus.ongoing).toList()
        : _filterIndex == 2
            ? allProjects.where((p) => p.status == ProjectStatus.future).toList()
            : allProjects;
    final allTasks   = ref.watch(tasksProvider);
    final now        = DateTime.now();
    // "Today" = due today, or undated but created today (so a task you just
    // added by voice shows up), plus anything overdue and still open.
    final todayTasks = allTasks.where((t) {
      final due = t.dueDate;
      if (due != null) {
        return DateUtils.isSameDay(due, now) ||
            (!t.isDone && due.isBefore(DateUtils.dateOnly(now)));
      }
      return DateUtils.isSameDay(t.createdAt, now);
    }).toList();
    final total      = todayTasks.length;
    final done       = todayTasks.where((t) => t.isDone).length;
    final previewTasks = (todayTasks.isNotEmpty ? todayTasks : allTasks).take(3).toList();
    final streak     = ref.watch(streakProvider);
    final topProject = projects.isNotEmpty ? projects.first : null;
    final gradientTitle =
        (topProject?.title.toUpperCase() ?? 'YOUR\nPLANS\nHERE');
    final gradientTimestamp = topProject != null
        ? _timeAgo(topProject.createdAt)
        : '';

    return Scaffold(
      backgroundColor: _bgTop,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Soft-focus pastel background ─────────────────────────────────
          const Positioned.fill(child: AuroraBackground()),

          // ── Scrollable content ───────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── Header icons ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        // 8-pointed star burst
                        const _StarBurst(),
                        const Spacer(),
                        // Grid icon pill → settings
                        GestureDetector(
                          onTap: () => context.go('/home/settings'),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.28),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1),
                            ),
                            child: Center(
                              child: _GridDots(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Big title ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Your plans',
                        style: AppTypography.displayLg(color: _ink)
                            .copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          fontSize: 26,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Filter chips ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final active = _filterIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.only(right: 10),
                          padding: EdgeInsets.symmetric(
                            horizontal: i == 0 ? 10 : 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? _chipActive
                                : Colors.white.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: active
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (i == 0) ...[
                                Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(right: 7),
                                  decoration: const BoxDecoration(
                                    color: _accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${allProjects.length}',
                                      style: AppTypography.micro(
                                              color: Colors.white)
                                          .copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                              Text(
                                _filters[i],
                                style: AppTypography.bodyMd(
                                  color: active
                                      ? const Color(0xFF1A1D18)
                                      : _ink.withValues(alpha: 0.75),
                                  weight: active
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // ── Bento grid ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 226,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 63,
                          child: _DarkTaskCard(tasks: previewTasks),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 37,
                          child: Column(
                            children: [
                              Expanded(
                                child: _StreakCard(streak: streak),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: _TodayCard(
                                  total: total,
                                  done: done,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // ── Wide gradient card ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _GradientCard(
                    title: gradientTitle,
                    timestamp: gradientTimestamp,
                    onTap: _showNewProjectSheet,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Project list ─────────────────────────────────────────
              if (projects.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = projects[i];
                      return _ProjectRow(
                        project: p,
                        onEdit: () => _showEditProjectSheet(p),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1C1E1A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Text('Delete plan?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                              content: Text(
                                '"${p.title}" will be permanently removed.',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Cancel',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.45))),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style: TextStyle(
                                          color: Color(0xFFE07070),
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            ref
                                .read(projectsProvider.notifier)
                                .deleteProject(p.id);
                          }
                        },
                      );
                    },
                    childCount: projects.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Star burst icon ───────────────────────────────────────────────────────────

class _StarBurst extends StatelessWidget {
  const _StarBurst();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: _StarPainter()),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _ink.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.42;

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

// ── Grid dots icon ────────────────────────────────────────────────────────────

class _GridDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: List.generate(
          9,
          (_) => Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ink.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dark task card ────────────────────────────────────────────────────────────

class _DarkTaskCard extends StatelessWidget {
  final List<dynamic> tasks;
  const _DarkTaskCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/home/tasks'),
      child: Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S\nTASKS",
            style: AppTypography.dotMatrix(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          ...tasks.map((t) => _TaskRow(label: t.title, done: t.isDone)),
          if (tasks.isEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: Icon(Icons.add_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Add your first task',
                    style: AppTypography.caption(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String label;
  final bool done;
  const _TaskRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _darkCard2,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? _checkFill : Colors.transparent,
              border: done
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5),
            ),
            child: done
                ? const Icon(Icons.check_rounded,
                    size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption(
                color: Colors.white.withValues(alpha: done ? 0.5 : 0.88),
              ).copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day streak card (top-right) ───────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    // Show the last 7 days as filled dots based on real streak count.
    final filledDots = streak.clamp(0, 7);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1630).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF7C6FD4).withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak',
                    style: AppTypography.dotMatrix(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 0,
                    ).copyWith(height: 1),
                  ),
                  Text(
                    'DAY STREAK',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB4A8FF).withValues(alpha: 0.85),
                      letterSpacing: 0.06 * 8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(streak > 0 ? '🔥' : '💤',
                  style: const TextStyle(fontSize: 20)),
            ],
          ),
          Row(
            children: List.generate(7, (i) {
              final filled = i < filledDots;
              final isToday = i == filledDots && i < 7;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 6 ? 3 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled
                        ? const Color(0xFF7C6FD4)
                        : isToday
                            ? const Color(0xFF7C6FD4).withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(2),
                    border: isToday
                        ? Border.all(
                            color: const Color(0xFF7C6FD4).withValues(alpha: 0.60),
                            width: 1,
                          )
                        : null,
                  ),
                ),
              );
            }),
          ),
          Text(
            streak > 0 ? 'Keep it going today' : 'Complete a task to start',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today stats card (bottom-right) ──────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final int total;
  final int done;
  const _TodayCard({required this.total, required this.done});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? done / total : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: glassDecoration(whiteAlpha: 0.22, borderAlpha: 0.35, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Today',
            style: AppTypography.micro(color: const Color(0xFF606060)),
          ),
          Text(
            '$total tasks',
            style: AppTypography.bodyLg(
                color: const Color(0xFF1A1A1A), weight: FontWeight.w700)
                .copyWith(fontSize: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.black.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C6FD4)),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$done of $total done',
                style: AppTypography.micro(
                    color: const Color(0xFF606060)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Gradient wide card ────────────────────────────────────────────────────────

class _GradientCard extends StatelessWidget {
  final String title;
  final String timestamp;
  final VoidCallback onTap;
  const _GradientCard({required this.title, required this.timestamp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: Aurora.holo,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              right: 0,
              child: _GridDotPattern(),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF32201E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0xFF32201E).withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'NEW PLAN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF32201E).withValues(alpha: 0.65),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (timestamp.isNotEmpty)
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF3C2850).withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.dotMatrix(
                          fontSize: 11,
                          color: const Color(0xFF32201E).withValues(alpha: 0.85),
                          letterSpacing: 1.5,
                        ).copyWith(height: 1.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF32201E).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF32201E).withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: const Color(0xFF32201E).withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid dot pattern (6×3 grid, matches HTML .dg) ────────────────────────────

class _GridDotPattern extends StatelessWidget {
  const _GridDotPattern();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: List.generate(18, (i) {
        final opacity = i >= 15 ? 0.10 + (17 - i) * 0.10 : 0.28;
        return Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3C2850).withValues(alpha: opacity),
          ),
        );
      }),
    );
  }
}

// ── Sheet section label ───────────────────────────────────────────────────────

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

// ── Project row ───────────────────────────────────────────────────────────────

class _ProjectRow extends StatelessWidget {
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProjectRow({required this.project, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      onLongPress: onDelete,
      child: NeumorphicCard(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        baseColor: _bgBottom,
        borderRadius: 18,
        child: Row(
          children: [
            Text(project.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_priorityDotColors[project.priorityIndex] != null) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _priorityDotColors[project.priorityIndex],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                      ],
                      Flexible(
                        child: Text(
                          project.title,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.dueDate != null
                        ? '${project.createdBy} · Due ${DateFormat('MMM d').format(project.dueDate!)}'
                        : project.createdBy,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: project.status == ProjectStatus.ongoing
                    ? _accent.withValues(alpha: 0.22)
                    : _ink.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                project.status == ProjectStatus.ongoing ? 'Ongoing' : 'Future',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: project.status == ProjectStatus.ongoing
                      ? const Color(0xFF4E3D8C)
                      : _inkSoft,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.more_horiz_rounded,
                size: 16, color: _ink.withValues(alpha: 0.50)),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _firstName(String name) =>
    name.isEmpty ? 'there' : name.split(' ').first;

int _priorityIndex(String? label) => switch (label) {
      'High' => 3,
      'Medium' => 2,
      'Low' => 1,
      _ => 0,
    };

const _priorityDotColors = [
  null, // none
  Color(0xFF5DB85D), // low
  Color(0xFFB9A6FF), // medium
  Color(0xFFE07070), // high
];
