import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class RevenueCard extends StatelessWidget {
  final String title;
  final String value;
  final String insight;

  const RevenueCard({
    super.key,
    required this.title,
    required this.value,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.adminPrimaryColor,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.adminPrimaryColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, size: 18, color: AppTheme.adminAccentRevenue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      color: AppTheme.adminTextColor.withOpacity(0.7), 
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
