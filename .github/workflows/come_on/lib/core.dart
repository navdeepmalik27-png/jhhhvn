import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _idc = 0;
String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idc++}';

class Task {
  Task(this.title, {String? id, this.done = false}) : id = id ?? newId();
  final String id;
  String title;
  bool done;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
  factory Task.fromJson(Map<String, dynamic> j) =>
      Task(j['title'] as String, id: j['id'] as String, done: j['done'] as bool);
}

class Project {
  Project(this.name, this.start, int n, {this.planned = false, List<List<Task>>? days})
      : days = days ?? List.generate(n, (_) => <Task>[]);
  final String name;
  final DateTime start; // local date, midnight
  bool planned; // true once every day has been planned
  final List<List<Task>> days;

  int get length => days.length;
  int dayIndex(DateTime d) => DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(start.year, start.month, start.day))
      .inDays;

  Map<String, dynamic> toJson() => {
        'name': name,
        'start': start.toIso8601String(),
        'planned': planned,
        'days': [for (final d in days) [for (final t in d) t.toJson()]],
      };
  factory Project.fromJson(Map<String, dynamic> j) {
    final days = [
      for (final d in j['days'] as List)
        [for (final t in d as List) Task.fromJson(t as Map<String, dynamic>)]
    ];
    return Project(j['name'] as String, DateTime.parse(j['start'] as String), days.length,
        planned: j['planned'] as bool, days: days);
  }
}

double ratio(List<Task> d) => d.isEmpty ? 1 : d.where((t) => t.done).length / d.length;

/// Figure position on the line: -1 = left end, 0 = center, +1 = right end.
///
/// progress = share of the whole project done so far (0..1) -> where the figure
///            stands if it is keeping pace; cumulative across days.
/// deficit  = how far today's tasks lag behind the clock (0..1). With n tasks,
///            the clock "expects" one task every 24h/n. Falling behind pulls the
///            figure left, reaching the left end at 24:00 if nothing is done.
double figureX(Project p, DateTime now) {
  final i = p.dayIndex(now), n = p.length;
  if (i < 0) return 0;
  double past = 0;
  for (var d = 0; d < n && d < i; d++) {
    past += ratio(p.days[d]);
  }
  if (i >= n) return past / n; // project over
  final today = p.days[i];
  final progress = (past + ratio(today)) / n;
  if (today.isEmpty) return progress;
  final k = today.where((t) => t.done).length;
  final tau = (now.hour * 3600 + now.minute * 60 + now.second) / 86400;
  final deficit = (tau * today.length - k).clamp(0, today.length) / today.length;
  return progress - deficit * (progress + 1);
}

class AppState extends ChangeNotifier {
  static const _key = 'project_v1';
  Project? project;
  bool loaded = false;

  Future<void> init() async {
    final s = (await SharedPreferences.getInstance()).getString(_key);
    if (s != null) {
      try {
        project = Project.fromJson(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {}
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> commit() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (project == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(project!.toJson()));
    }
  }

  Future<void> create(String name, int days) {
    final n = DateTime.now();
    project = Project(name, DateTime(n.year, n.month, n.day), days);
    return commit();
  }

  Future<void> finishSetup() {
    project!.planned = true;
    return commit();
  }

  Future<void> toggle(Task t) {
    t.done = !t.done;
    return commit();
  }

  Future<void> reset() {
    project = null;
    return commit();
  }
}
