import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveFilterChipsWidget extends StatelessWidget {
  final String activeFilter;
  final Map<String, int> counts;
  final ValueChanged<String> onFilterChanged;

  const LeaveFilterChipsWidget({
    required this.activeFilter,
    required this.counts,
    required this.onFilterChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ['All', 'Pending', 'Approved', 'Declined'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isActive = activeFilter == filter;
          final count = counts[filter] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onFilterChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(51),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(
                      filter,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withAlpha(64)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
