import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorime_v1/models/time_capsule.dart';

class CapsuleGridView extends StatelessWidget {
  final List<TimeCapsule> capsules;
  final DateTime month;
  const CapsuleGridView({
    super.key,
    required this.capsules,
    required this.month,
    });

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final String monthTitle =
        "${_monthName(month.month)} ${month.year}";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Text(
              monthTitle,
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
              ),
            ),
          ),
          
          // Grid View
          Expanded(
            child: GridView.builder(
              itemCount: daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              
              itemBuilder: (context, index) {
                final day = index + 1;
                final DateTime cellDate = DateTime(month.year, month.month, day);
                final capsuleForDay = _findCapsuleForDay(capsules, day, month.month, month.year);

                final bool hasCapsule = capsuleForDay != null;

                final isToday = DateTime.now().day == day &&
                    DateTime.now().month == month.month &&
                    DateTime.now().year == month.year;

print("CellDate: ${DateTime(month.year, month.month, day)}");
                bool _isSameDay(DateTime a, DateTime b) {
                    return a.year == b.year && a.month == b.month && a.day == b.day;
                  }

                final bool isUnlockDay = hasCapsule && _isSameDay(capsuleForDay!.unlockDate, cellDate);

                return GestureDetector(
                  onTap: hasCapsule
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Capsule: ${capsuleForDay!.title}")),
                          );
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUnlockDay ? Colors.blueAccent : 
                      isToday ?Colors.cyan.withOpacity(0.3) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                    children: [
                      // Day number in top-left
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Text(
                          "$day",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Lock icon centered if locked
                      if (isUnlockDay)
                        const Center(
                          child: Icon(Icons.lock, color: Colors.white, size: 20),
                        ),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
    /// Helper to find the capsule for a given day, or null if none exists
  TimeCapsule? _findCapsuleForDay(List<TimeCapsule> capsules, int day, int month, int year) {
    final DateTime cellDate = DateTime(year, month, day);
    
    for(var capsule in capsules){
      print("Capsule: ${capsule.title} | Unlock: ${capsule.unlockDate}");
      final unlockedDate = DateTime(
        capsule.unlockDate.year,
        capsule.unlockDate.month,
        capsule.unlockDate.day,
      );

      if (unlockedDate.year == cellDate.year &&
        unlockedDate.month == cellDate.month &&
        unlockedDate.day == cellDate.day) {
        return capsule;
      }
    }
    return null;
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}





