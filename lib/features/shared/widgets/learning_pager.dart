import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class LearningPager extends StatelessWidget {
  final int itemCount;
  final int initialIndex;
  final PageController controller;
  final IndexedWidgetBuilder itemBuilder;
  final VoidCallback? onComplete;
  final ValueChanged<int>? onIndexChanged;
  final String completeMessage;

  const LearningPager({
    super.key,
    required this.itemCount,
    required this.controller,
    required this.itemBuilder,
    this.initialIndex = 0,
    this.onComplete,
    this.onIndexChanged,
    this.completeMessage = 'Con đã học hết phần này rồi! 🎉',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: controller,
            physics: const ClampingScrollPhysics(),
            itemCount: itemCount,
            onPageChanged: onIndexChanged,
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }
}

class LessonNavBar extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onPractice;

  const LessonNavBar({
    super.key,
    required this.index,
    required this.total,
    required this.onPrevious,
    required this.onNext,
    this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    final last = index >= total - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: index == 0 ? null : onPrevious,
            style: OutlinedButton.styleFrom(minimumSize: const Size(88, 48)),
            child: const Text('← Trước'),
          ),
          if (onPractice != null)
            OutlinedButton(
              onPressed: onPractice,
              style: OutlinedButton.styleFrom(minimumSize: const Size(88, 48)),
              child: const Text('Luyện tập'),
            ),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
            child: Text(last ? 'Xong rồi' : 'Tiếp tục'),
          ),
        ],
      ),
    );
  }
}

class LessonCompleteCard extends StatelessWidget {
  final VoidCallback onReview;
  final VoidCallback onOther;
  final VoidCallback onBack;

  const LessonCompleteCard({
    super.key,
    required this.onReview,
    required this.onOther,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Con đã học hết phần này rồi! 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onReview, child: const Text('Ôn lại')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onOther, child: const Text('Chọn bài khác')),
          TextButton(onPressed: onBack, child: const Text('Về trang trước', style: TextStyle(color: AppTheme.textLight))),
        ],
      ),
    );
  }
}
