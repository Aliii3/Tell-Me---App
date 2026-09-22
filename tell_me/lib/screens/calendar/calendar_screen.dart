import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_provider.dart';
import '../../theme/app_typography.dart';
import '../../theme/aurora.dart';
import '../../widgets/neumorphic_card.dart';

const _bgTop    = Color(0xFFC5CCBF);
const _bgBottom = Color(0xFFBBB5AC);
const _accent   = Color(0xFF7C6FD4);
// Dark ink for text on the light sage background (white failed WCAG contrast).
const _ink      = Color(0xFF23261E);
const _inkSoft  = Color(0xFF565C4C);

const _categories = ['General', 'Team', 'Product', 'Break'];
const _durations  = ['30 min', '1 hr', '1.5 hrs', '2 hrs'];

// Maps event category → card color scheme
_CardStyle _styleFor(CalendarEvent e, int index) {
  final cat = e.category.toLowerCase();
  if (cat.contains('team') || cat.contains('stand')) {
    return _CardStyle(
      bg: const Color(0xFFF08264).withValues(alpha: 0.22),
      border: const Color(0xFFF08264).withValues(alpha: 0.38),
    );
  }
  if (cat.contains('product') || cat.contains('design')) {
    return _CardStyle(
      bg: const Color(0xFF64C896).withValues(alpha: 0.22),
      border: const Color(0xFF64C896).withValues(alpha: 0.38),
    );
  }
  if (cat.contains('break') || cat.contains('lunch')) {
    return _CardStyle(
      bg: const Color(0xFF7C6FD4).withValues(alpha: 0.30),
      border: const Color(0xFF7C6FD4).withValues(alpha: 0.45),
    );
  }
  final styles = [
    _CardStyle(bg: const Color(0xFF64C896).withValues(alpha: 0.22), border: const Color(0xFF64C896).withValues(alpha: 0.38)),
    _CardStyle(bg: const Color(0xFF7C6FD4).withValues(alpha: 0.30), border: const Color(0xFF7C6FD4).withValues(alpha: 0.45)),
    _CardStyle(bg: const Color(0xFFF08264).withValues(alpha: 0.22), border: const Color(0xFFF08264).withValues(alpha: 0.38)),
  ];
  return styles[index % 3];
}

class _CardStyle {
  final Color bg;
  final Color border;
  const _CardStyle({required this.bg, required this.border});
}

TimeOfDay? _parseTime(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
}

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Unified add/edit sheet. Pass [existing] to edit; otherwise creates a new
/// event on [forDate].
void _showEventSheet(
  BuildContext context,
  WidgetRef ref, {
  CalendarEvent? existing,
  required DateTime forDate,
}) {
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  var selectedTime =
      existing != null ? _parseTime(existing.time) ?? const TimeOfDay(hour: 9, minute: 0) : const TimeOfDay(hour: 9, minute: 0);
  var selectedDuration = existing?.duration ?? '1 hr';
  var selectedCategory =
      _categories.contains(existing?.category) ? existing!.category : 'General';
  final isEditing = existing != null;

  showModalBottomSheet<void>(
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
                  Text(isEditing ? 'EDIT EVENT' : 'NEW EVENT',
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

                const _SheetLabel(label: 'EVENT TITLE'),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  autofocus: !isEditing,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'What\'s happening?',
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

                const SizedBox(height: 20),

                // Time picker + duration chips
                const _SheetLabel(label: 'TIME'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: _accent, surface: Color(0xFF1C1E1A),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setSheet(() => selectedTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF7C6FD4).withValues(alpha: 0.38), width: 1.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.schedule_rounded, size: 16, color: _accent),
                      const SizedBox(width: 10),
                      Text(selectedTime.format(ctx),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),

                const SizedBox(height: 16),

                const _SheetLabel(label: 'DURATION'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _durations.map((d) {
                    final active = selectedDuration == d;
                    return GestureDetector(
                      onTap: () => setSheet(() => selectedDuration = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF3D3568) : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(d, style: TextStyle(
                          color: active ? Colors.white : Colors.white.withValues(alpha: 0.55),
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400, fontSize: 13,
                        )),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                const _SheetLabel(label: 'CATEGORY'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _categories.map((c) {
                    final active = selectedCategory == c;
                    return GestureDetector(
                      onTap: () => setSheet(() => selectedCategory = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF3D3568) : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(c, style: TextStyle(
                          color: active ? Colors.white : Colors.white.withValues(alpha: 0.55),
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400, fontSize: 13,
                        )),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 26),

                GestureDetector(
                  onTap: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    final notifier = ref.read(calendarNotifierProvider.notifier);
                    if (isEditing) {
                      final prevKey = existing.dateKey;
                      notifier.updateEvent(
                        CalendarEvent(
                          id: existing.id,
                          dateKey: dateKey(forDate),
                          title: title,
                          time: _hhmm(selectedTime),
                          duration: selectedDuration,
                          category: selectedCategory,
                          backgroundColor: existing.backgroundColor,
                          textColor: existing.textColor,
                          avatars: existing.avatars,
                          hasVideo: existing.hasVideo,
                        ),
                        previousKey: prevKey,
                      );
                    } else {
                      notifier.addEvent(CalendarEvent(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        dateKey: dateKey(forDate),
                        title: title,
                        time: _hhmm(selectedTime),
                        duration: selectedDuration,
                        category: selectedCategory,
                        backgroundColor: const Color(0xFF7C6FD4),
                      ));
                    }
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
                      child: Text(isEditing ? 'Save changes →' : 'Create event →',
                          style: AppTypography.bodyLg(color: Colors.white, weight: FontWeight.w700)
                              .copyWith(fontSize: 16)),
                    ),
                  ),
                ),

                if (isEditing) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        ref.read(calendarNotifierProvider.notifier)
                            .deleteEvent(existing.id, existing.dateKey);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: Color(0xFFE07070)),
                      label: const Text('Delete event',
                          style: TextStyle(color: Color(0xFFE07070), fontSize: 14)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final selected = ref.watch(selectedDateProvider);
    final events = ref.watch(calendarEventsProvider);

    // Week strip is anchored to the week containing the *selected* day, so
    // paging the selection moves through weeks/months/years freely.
    final monday = DateUtils.dateOnly(selected)
        .subtract(Duration(days: selected.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    void shiftWeek(int deltaDays) {
      ref.read(selectedDateProvider.notifier).state =
          selected.add(Duration(days: deltaDays));
    }

    final isThisWeek = !monday.isAfter(DateUtils.dateOnly(today)) &&
        monday.add(const Duration(days: 7)).isAfter(DateUtils.dateOnly(today));

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
                          if (!isThisWeek)
                            GestureDetector(
                              onTap: () => ref
                                  .read(selectedDateProvider.notifier)
                                  .state = DateTime.now(),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text('Today',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _ink.withValues(alpha: 0.80))),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _showEventSheet(context, ref,
                                forDate: selected),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _ink.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 18, color: _ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Title + month nav ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Text(
                            'Schedule',
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

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // ── Week nav row (‹ Month YYYY ›) ─────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _NavArrow(
                            icon: Icons.chevron_left_rounded,
                            onTap: () => shiftWeek(-7),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selected,
                                  firstDate: DateTime(today.year - 2),
                                  lastDate: DateTime(today.year + 5),
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
                                  ref
                                      .read(selectedDateProvider.notifier)
                                      .state = picked;
                                }
                              },
                              child: Center(
                                child: Text(
                                  DateFormat('MMMM yyyy').format(selected),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _NavArrow(
                            icon: Icons.chevron_right_rounded,
                            onTap: () => shiftWeek(7),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Week strip ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: List.generate(7, (i) {
                          final day = weekDays[i];
                          final isSelected = DateUtils.isSameDay(day, selected);
                          final isToday = DateUtils.isSameDay(day, today);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(selectedDateProvider.notifier)
                                  .state = day,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _accent.withValues(alpha: 0.75)
                                      : Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color:
                                              Colors.white.withValues(alpha: 0.65),
                                          width: 1)
                                      : isToday
                                          ? Border.all(
                                              color: _ink.withValues(alpha: 0.30),
                                              width: 1)
                                          : Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.50),
                                              width: 1),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      dayNames[i],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.85)
                                            : _inkSoft,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : _ink,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // ── Date label ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${selected.day}',
                            style: AppTypography.dotMatrix(
                              fontSize: 34,
                              color: _ink,
                              letterSpacing: 0,
                            ).copyWith(height: 1),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _dateLabel(selected, today),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _inkSoft,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Events ────────────────────────────────────────────
                  if (events.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
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
                                Icons.calendar_today_outlined,
                                size: 22,
                                color: _ink.withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Nothing scheduled',
                              style: AppTypography.bodyMd(
                                color: _ink,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap + to add an event',
                              style: AppTypography.caption(color: _inkSoft),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _EventBlock(
                          event: events[i],
                          style: _styleFor(events[i], i),
                          onTap: () => _showEventSheet(context, ref,
                              existing: events[i], forDate: selected),
                        ),
                        childCount: events.length,
                      ),
                    ),

                  // ── Always show an add-event slot at end ──────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _EmptySlot(
                          onTap: () =>
                              _showEventSheet(context, ref, forDate: selected)),
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

  static String _dateLabel(DateTime selected, DateTime today) {
    final selDay = DateUtils.dateOnly(selected);
    final todayDay = DateUtils.dateOnly(today);
    final diff = selDay.difference(todayDay).inDays;
    final prefix = diff == 0
        ? 'TODAY'
        : diff == 1
            ? 'TOMORROW'
            : diff == -1
                ? 'YESTERDAY'
                : DateFormat('EEE').format(selected).toUpperCase();
    return '$prefix · ${DateFormat('MMM').format(selected).toUpperCase()} ${selected.day}';
  }
}

// ── Week nav arrow ─────────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 24, color: _ink.withValues(alpha: 0.70)),
      ),
    );
  }
}

// ── Event block (real data) ───────────────────────────────────────────────────

class _EventBlock extends StatelessWidget {
  final CalendarEvent event;
  final _CardStyle style;
  final VoidCallback? onTap;
  const _EventBlock({required this.event, required this.style, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 46,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _formatTime(event.time),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _inkSoft,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: style.bg,
                  border: Border.all(color: style.border, width: 1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTypography.bodySm(
                        color: _ink,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatTime(event.time)} · ${event.duration}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(String time) {
    // "10:00" → "10:00 AM", "15:30" → "3:30 PM"
    final parsed = _parseTime(time);
    if (parsed == null) return time;
    final h = parsed.hour;
    final m = parsed.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }
}

// ── Empty / add-event slot ────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  final VoidCallback? onTap;
  const _EmptySlot({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        baseColor: _bgBottom.withValues(alpha: 0.85),
        borderRadius: 13,
        child: Row(
          children: [
            Icon(Icons.add_rounded, size: 16, color: _ink.withValues(alpha: 0.65)),
            const SizedBox(width: 8),
            Text(
              'Add event',
              style: TextStyle(
                fontSize: 12,
                color: _ink.withValues(alpha: 0.80),
                fontWeight: FontWeight.w600,
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
