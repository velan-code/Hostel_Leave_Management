import 'package:flutter/material.dart';

class GreetingHeaderWidget extends StatelessWidget {
  final String name;
  final String roomNumber;
  final String? hostelBlock;

  const GreetingHeaderWidget({
    required this.name,
    required this.roomNumber,
    this.hostelBlock,
    super.key,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = name.isNotEmpty ? name.split(' ').first : 'Student';
    final block = hostelBlock?.isNotEmpty == true ? hostelBlock! : 'Hostel Block A';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_greeting()}, $firstName 👋',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(
              'Room ${roomNumber.isNotEmpty ? roomNumber : 'N/A'} · $block',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
