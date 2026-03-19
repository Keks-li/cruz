void main() {
  final now = DateTime.now();
  final selectedDate = DateTime(2023, 10, 2);
  final isBackdated =
      selectedDate != null &&
      DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      ).isBefore(
        DateTime(now.year, now.month, now.day),
      );
  print(isBackdated);
}
