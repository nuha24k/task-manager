import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CalendarMeetingScreen extends StatefulWidget {
  const CalendarMeetingScreen({super.key});

  @override
  State<CalendarMeetingScreen> createState() => _CalendarMeetingScreenState();
}

class _CalendarMeetingScreenState extends State<CalendarMeetingScreen> {
  int _selectedDay = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Header Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.darkText),
                    onPressed: () {},
                  ),
                  const Text(
                    'November 2025',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.darkText),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Calendar Grid Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    // Days of week row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['1', '2', '3', '4', '5', '6']
                          .map((d) => SizedBox(
                                width: 32,
                                child: Text(
                                  d,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.subText, fontSize: 13),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    // Days Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 30,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final dayNumber = index + 1;
                        final isSelected = dayNumber == _selectedDay;
                        final isHighlighted = [12, 14, 18, 20, 25, 28].contains(dayNumber);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = dayNumber),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.blackButton
                                  : (isHighlighted ? AppColors.accentYellow : Colors.transparent),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected || isHighlighted ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppColors.darkText,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Today's Meeting Section
              const Text(
                "Today's meeting",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 12),

              _buildMeetingCard('1.30 AM - 2.00 AM', 'https://i.pravatar.cc/100?img=11'),
              const SizedBox(height: 10),
              _buildMeetingCard('2.40 AM - 3.30 AM', 'https://i.pravatar.cc/100?img=14'),

              const SizedBox(height: 24),

              // Delivery App UI Kit Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery App UI Kit',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCard,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.space_dashboard_rounded, size: 16, color: AppColors.darkText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We got a project to make a delivery ui kit called Foodnow...',
                      style: TextStyle(fontSize: 13, color: AppColors.subText),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildAvatar('https://i.pravatar.cc/100?img=21'),
                            Transform.translate(
                              offset: const Offset(-8, 0),
                              child: _buildAvatar('https://i.pravatar.cc/100?img=22'),
                            ),
                            Transform.translate(
                              offset: const Offset(-16, 0),
                              child: const CircleAvatar(
                                radius: 11,
                                backgroundColor: AppColors.chipBackground,
                                child: Text('+3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const Text('65%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.subText)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 6,
                        backgroundColor: AppColors.chipBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.priorityHigh),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(String time, String avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.subText),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blackButton,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {},
            child: const Text('Join meet', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 11,
        backgroundImage: NetworkImage(url),
      ),
    );
  }
}
