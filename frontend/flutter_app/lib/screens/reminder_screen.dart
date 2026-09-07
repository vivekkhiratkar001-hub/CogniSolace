import 'package:flutter/material.dart';

/// Today's Routine & Reminder Screen for COGNISOLACE
///
/// Project: AI-Based Cognitive Gaming and Memory Assistance Platform
///          for Elderly Dementia Patients in North Eastern Region (NER)
///
/// Role: Member 1 – Flutter Frontend Developer
///
/// Purpose:
/// - Displays clear daily schedule cards tailored for elderly users.
/// - Minimal cognitive load with large text, simple icons, and high-contrast time badges.
/// - Uses dummy data initially; will connect to backend FastAPI endpoints later.
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  // Theme colors (Warm Amber/Orange for daily routines & Tea Garden Green)
  static const Color routineOrange = Color(0xFFD84315);
  static const Color completedGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF7FAF7);
  static const Color textPrimary = Color(0xFF1A2E22);
  static const Color textSecondary = Color(0xFF37474F);

  // Initial dummy schedule data
  final List<Map<String, dynamic>> _routines = [
    {
      'id': 'routine_1',
      'emoji': '🌅',
      'time': '8:00 AM',
      'title': 'Morning Exercise',
      'icon': Icons.wb_sunny_rounded,
      'isCompleted': false,
    },
    {
      'id': 'routine_2',
      'emoji': '💊',
      'time': '9:00 AM',
      'title': 'Medicine Reminder',
      'icon': Icons.medication_rounded,
      'isCompleted': true,
    },
    {
      'id': 'routine_3',
      'emoji': '🍽️',
      'time': '1:00 PM',
      'title': 'Lunch Time',
      'icon': Icons.restaurant_rounded,
      'isCompleted': false,
    },
    {
      'id': 'routine_4',
      'emoji': '🚶',
      'time': '5:00 PM',
      'title': 'Evening Walk',
      'icon': Icons.directions_walk_rounded,
      'isCompleted': false,
    },
    {
      'id': 'routine_5',
      'emoji': '🌙',
      'time': '9:00 PM',
      'title': 'Sleep Reminder',
      'icon': Icons.bedtime_rounded,
      'isCompleted': false,
    },
  ];

  /// Displays an elderly-friendly SnackBar confirmation
  void _showNotification(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess ? completedGreen : routineOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.all(20.0),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Toggles task completion state with reassuring feedback
  void _toggleRoutine(int index) {
    setState(() {
      _routines[index]['isCompleted'] = !_routines[index]['isCompleted'];
    });

    final routine = _routines[index];
    final isDone = routine['isCompleted'] as bool;
    final title = routine['title'] as String;

    if (isDone) {
      _showNotification('Great job! "$title" completed. 🎉', isSuccess: true);
    } else {
      _showNotification('"$title" marked as pending.');
    }
  }

  /// Placeholder for adding new reminders (will connect to backend APIs later)
  void _onAddReminder() {
    _showNotification('Add Reminder will connect to the backend server soon.');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: backgroundColor,

      // 1. Clear AppBar with Title and Large Back Button
      appBar: AppBar(
        backgroundColor: routineOrange,
        foregroundColor: Colors.white,
        elevation: 2.0,
        toolbarHeight: 72.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32.0),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Today's Routine",
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Responsive constraint: prevents awkward stretching on wide screens
            constraints: const BoxConstraints(maxWidth: 680.0),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32.0 : 20.0,
                vertical: 20.0,
              ),
              children: [
                // Encouraging Section Heading
                Text(
                  'Daily Schedule',
                  style: TextStyle(
                    fontSize: isTablet ? 26.0 : 22.0,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(height: 6.0),

                // Friendly instructions
                Text(
                  'Tap any card to mark it as done.',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20.0),

                // 2. Large Routine Cards
                for (int i = 0; i < _routines.length; i++) ...[
                  _buildRoutineCard(_routines[i], i, isTablet),
                  const SizedBox(height: 16.0),
                ],

                const SizedBox(height: 12.0),

                // 3. Large "+ Add Reminder" Button
                _buildAddReminderButton(isTablet),

                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds an individual large routine card for dementia accessibility
  Widget _buildRoutineCard(Map<String, dynamic> item, int index, bool isTablet) {
    final isCompleted = item['isCompleted'] as bool;
    final emoji = item['emoji'] as String;
    final time = item['time'] as String;
    final title = item['title'] as String;
    final icon = item['icon'] as IconData;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22.0),
      elevation: 2.5,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.0),
        onTap: () => _toggleRoutine(index),
        child: Container(
          constraints: BoxConstraints(
            minHeight: isTablet ? 104.0 : 90.0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 22.0 : 18.0,
            vertical: 16.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(
              color: isCompleted
                  ? completedGreen.withValues(alpha: 0.5)
                  : Colors.grey.shade300,
              width: isCompleted ? 2.0 : 1.5,
            ),
          ),
          child: Row(
            children: [
              // Large Checkbox Circle
              Container(
                width: isTablet ? 54.0 : 46.0,
                height: isTablet ? 54.0 : 46.0,
                decoration: BoxDecoration(
                  color: isCompleted ? completedGreen : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? completedGreen : Colors.grey.shade400,
                    width: 2.0,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : Icons.circle_outlined,
                  color: isCompleted ? Colors.white : Colors.grey.shade400,
                  size: isTablet ? 34.0 : 28.0,
                ),
              ),

              const SizedBox(width: 16.0),

              // Routine Text Info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: routineOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '$emoji  $time',
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: routineOrange,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6.0),

                    // Routine Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isTablet ? 22.0 : 19.0,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? completedGreen : textPrimary,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8.0),

              // Activity Icon Avatar
              Container(
                width: isTablet ? 54.0 : 46.0,
                height: isTablet ? 54.0 : 46.0,
                decoration: BoxDecoration(
                  color: (isCompleted ? completedGreen : routineOrange)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: isTablet ? 28.0 : 24.0,
                    color: isCompleted ? completedGreen : routineOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the large "+ Add Reminder" button
  Widget _buildAddReminderButton(bool isTablet) {
    return ElevatedButton(
      onPressed: _onAddReminder,
      style: ElevatedButton.styleFrom(
        backgroundColor: routineOrange,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, isTablet ? 64.0 : 56.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        elevation: 3.0,
        padding: const EdgeInsets.symmetric(vertical: 14.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            size: isTablet ? 32.0 : 28.0,
          ),
          const SizedBox(width: 10.0),
          Text(
            '+ Add Reminder',
            style: TextStyle(
              fontSize: isTablet ? 22.0 : 19.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
