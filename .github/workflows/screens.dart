import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'stage.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String dateOf(Project p, int d) {
  final t = DateTime(p.start.year, p.start.month, p.start.day + d);
  return '${t.day} ${_months[t.month - 1]}';
}

Future<void> confirmReset(BuildContext c, AppState s) async {
  final ok = await showDialog<bool>(
    context: c,
    builder: (d) => AlertDialog(
      title: const Text('Start over?'),
      content: const Text('This deletes the project and all its tasks.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
      ],
    ),
  );
  if (ok == true) await s.reset();
}

// ---------------------------------------------------------------- create
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.state});
  final AppState state;
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _name = TextEditingController();
  final _days = TextEditingController(text: '30');

  void _go() {
    final n = int.tryParse(_days.text);
    if (n == null || n < 1 || n > 365) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 1 to 365 days')));
      return;
    }
    widget.state.create(_name.text.trim().isEmpty ? 'My project' : _name.text.trim(), n);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
                Text('Come on', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                const Text('How many days does your project run?'),
                const SizedBox(height: 24),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Project name', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Length', suffixText: 'days', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  for (final n in [7, 14, 30, 60, 90]) ActionChip(label: Text('$n'), onPressed: () => _days.text = '$n'),
                ]),
                const SizedBox(height: 24),
                FilledButton(onPressed: _go, child: const Text('Lay out calendar')),
              ]),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------- plan / calendar
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key, required this.state, required this.setup});
  final AppState state;
  final bool setup; // true: first-time planning; false: calendar view from home

  void _open(BuildContext c, int i) {
    final p = state.project!;
    final t = p.dayIndex(DateTime.now());
    showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DaySheet(state: state, day: i, canEdit: setup || i >= t, canCheck: !setup && i <= t),
    );
  }

  Widget _month(BuildContext c, Project p, int y, int m) {
    final cs = Theme.of(c).colorScheme;
    final first = DateTime(y, m, 1);
    final today = p.dayIndex(DateTime.now());
    final cells = <Widget>[for (var i = 1; i < first.weekday; i++) const SizedBox()];
    for (var d = 1; d <= DateTime(y, m + 1, 0).day; d++) {
      final i = p.dayIndex(DateTime(y, m, d));
      if (i < 0 || i >= p.length) {
        cells.add(Center(child: Text('$d', style: TextStyle(color: cs.onSurface.withAlpha(60)))));
        continue;
      }
      final tasks = p.days[i];
      final done = tasks.isNotEmpty && tasks.every((t) => t.done);
      cells.add(Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: done ? cs.tertiaryContainer : (tasks.isEmpty ? cs.surfaceContainerHigh : cs.primaryContainer),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: (!setup && i == today) ? BorderSide(color: cs.primary, width: 2) : BorderSide.none),
          child: InkWell(
            onTap: () => _open(c, i),
            child: Center(child: Text('$d', style: const TextStyle(fontWeight: FontWeight.w600))),
          ),
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text('${_months[m - 1]} $y', style: Theme.of(c).textTheme.titleMedium)),
      GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cells),
    ]);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final p = state.project;
          if (p == null) return const SizedBox();
          final end = DateTime(p.start.year, p.start.month, p.start.day + p.length - 1);
          final months = <(int, int)>[];
          var y = p.start.year, m = p.start.month;
          while (y < end.year || (y == end.year && m <= end.month)) {
            months.add((y, m));
            if (++m > 12) {
              m = 1;
              y++;
            }
          }
          final planned = p.days.where((d) => d.isNotEmpty).length;
          return Scaffold(
            appBar: AppBar(
              title: Text(setup ? 'Plan every day' : 'Calendar'),
              actions: setup
                  ? [
                      PopupMenuButton<int>(
                        onSelected: (_) => confirmReset(context, state),
                        itemBuilder: (_) => const [PopupMenuItem(value: 0, child: Text('Start over'))],
                      )
                    ]
                  : null,
            ),
            bottomNavigationBar: setup
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton(
                        onPressed: planned == p.length ? state.finishSetup : null,
                        child: Text(planned == p.length ? 'Start project' : '$planned of ${p.length} days planned'),
                      ),
                    ),
                  )
                : null,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                  if (setup) ...[
                    const Text('Tap a day and add what must be done that day.'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: planned / p.length),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(children: [
                      for (final d in 'MTWTFSS'.split(''))
                        Expanded(child: Center(child: Text(d, style: Theme.of(context).textTheme.labelSmall)))
                    ]),
                  ),
                  for (final (yy, mm) in months) _month(context, p, yy, mm),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          );
        },
      );
}

// ---------------------------------------------------------------- day sheet
class DaySheet extends StatefulWidget {
  const DaySheet({super.key, required this.state, required this.day, required this.canEdit, required this.canCheck});
  final AppState state;
  final int day;
  final bool canEdit, canCheck;
  @override
  State<DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<DaySheet> {
  final _c = TextEditingController();
  final _f = FocusNode();

  void _add() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    widget.state.project!.days[widget.day].add(Task(t));
    widget.state.commit();
    _c.clear();
    _f.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.state.project!;
    final tasks = p.days[widget.day];
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Day ${widget.day + 1} · ${dateOf(p, widget.day)}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Flexible(
          child: ListView(shrinkWrap: true, children: [
            for (final t in tasks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: widget.canCheck
                    ? Checkbox(
                        value: t.done,
                        onChanged: (_) {
                          widget.state.toggle(t);
                          setState(() {});
                        })
                    : null,
                title: Text(t.title, style: t.done ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                trailing: widget.canEdit
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          tasks.remove(t);
                          widget.state.commit();
                          setState(() {});
                        })
                    : null,
              ),
          ]),
        ),
        if (widget.canEdit)
          Row(children: [
            Expanded(
              child: TextField(
                controller: _c,
                focusNode: _f,
                autofocus: tasks.isEmpty,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: const InputDecoration(hintText: 'Add a task'),
              ),
            ),
            IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
          ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------- home
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});
  final AppState state;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {}); // the clock moves the figure
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.state.project!;
    final now = DateTime.now();
    final i = p.dayIndex(now);
    final over = i >= p.length;
    final today = over ? <Task>[] : p.days[i];
    final done = today.where((t) => t.done).length;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(p.name),
        actions: [
          IconButton(
            tooltip: 'Calendar',
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PlanScreen(state: widget.state, setup: false))),
          ),
          PopupMenuButton<int>(
            onSelected: (_) => confirmReset(context, widget.state),
            itemBuilder: (_) => const [PopupMenuItem(value: 0, child: Text('Start over'))],
          ),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        PixelStage(targetX: figureX(p, now)),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  color: const Color(0xE6171920),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Expanded(child: Text(over ? 'Project finished' : 'Day ${i + 1} of ${p.length}',
                            style: Theme.of(context).textTheme.titleMedium)),
                        if (!over) Text('$done / ${today.length} today'),
                      ]),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 4,
                        value: p.days.fold<double>(0, (a, d) => a + ratio(d)) / p.length,
                      ),
                      const SizedBox(height: 8),
                      if (!over)
                        TextButton.icon(
                          icon: const Icon(Icons.checklist_rounded),
                          label: Text(done == today.length ? 'All done · View tasks' : "Today's tasks"),
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => DaySheet(state: widget.state, day: i,
                                canEdit: false, canCheck: true),
                          ),
                        )
                      else
                        const Text('The run is over.'),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
