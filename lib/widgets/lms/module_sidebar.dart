import 'package:flutter/material.dart';

import '../../theme.dart';
import 'content_viewer.dart';

/// Left-hand module list. Shows done / current / not-started icons.
/// Used as a fixed panel on wide screens and inside a Drawer on phones.
class ModuleSidebar extends StatelessWidget {
  const ModuleSidebar({
    super.key,
    required this.lessons,
    required this.currentIndex,
    required this.completed,
    required this.onSelect,
  });

  final List<PlayerLesson> lessons;
  final int currentIndex;
  final Set<int> completed;
  final ValueChanged<int> onSelect;

  Widget _icon(bool done, bool current) {
    if (done) return const Icon(Icons.check_circle, color: purple, size: 22);
    if (current) {
      return const Icon(Icons.play_circle_fill, color: deepBlue, size: 22);
    }
    return const Icon(
      Icons.radio_button_unchecked,
      color: Colors.black38,
      size: 22,
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          'Course content',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: deepBlue,
          ),
        ),
      ),
    ];

    for (var i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final firstInModule =
          i == 0 || lessons[i - 1].moduleIndex != lesson.moduleIndex;
      if (firstInModule) {
        final indexes = [
          for (var j = 0; j < lessons.length; j++)
            if (lessons[j].moduleIndex == lesson.moduleIndex) j,
        ];
        final moduleDone = indexes.every(completed.contains);
        final moduleCurrent = indexes.contains(currentIndex);
        children.add(
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: moduleCurrent
                ? softYellow.withValues(alpha: .28)
                : Colors.transparent,
            child: Row(
              children: [
                _icon(moduleDone, moduleCurrent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Module ${lesson.moduleIndex + 1}: ${lesson.moduleTitle}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: deepBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      final isCurrent = i == currentIndex;
      children.add(
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 52, right: 16),
          selected: isCurrent,
          selectedColor: deepBlue,
          title: Text(
            lesson.title,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          trailing: _icon(completed.contains(i), isCurrent),
          onTap: () => onSelect(i),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: ListView(children: children),
    );
  }
}
