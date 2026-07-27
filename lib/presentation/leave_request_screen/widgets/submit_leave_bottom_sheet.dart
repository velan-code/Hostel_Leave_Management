import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class SubmitLeaveBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final String? studentName;
  final String? rollNo;
  const SubmitLeaveBottomSheet({
    super.key,
    required this.onSubmit,
    this.studentName,
    this.rollNo,
  });

  @override
  State<SubmitLeaveBottomSheet> createState() => _SubmitLeaveBottomSheetState();
}

class _SubmitLeaveBottomSheetState extends State<SubmitLeaveBottomSheet> {
  final _reasonController = TextEditingController();
  String _selectedType = 'Home Visit';
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _departureTime = const TimeOfDay(hour: 16, minute: 20);
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 9, minute: 0);

  final List<String> _leaveTypes = [
    'Home Visit',
    'Medical',
    'Emergency',
    'Festival',
    'Other',
  ];

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) {
            _toDate = _fromDate.add(const Duration(days: 1));
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isDeparture) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isDeparture ? _departureTime : _arrivalTime,
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureTime = picked;
        } else {
          _arrivalTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a reason for leave',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    final newRequest = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': _selectedType,
      'fromDate': _formatDate(_fromDate),
      'toDate': _formatDate(_toDate),
      'departureTime': _formatTime(_departureTime),
      'arrivalTime': _formatTime(_arrivalTime),
      'reason': _reasonController.text.trim(),
      'status': 'pending',
      'classMamSigned': true,
      'hodSigned': false,
      'wardenSigned': false,
      'submittedOn': _formatDate(DateTime.now()),
    };
    widget.onSubmit(newRequest);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Leave request submitted successfully!',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: AppTheme.wardenAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              5.w,
              0,
              5.w,
              MediaQuery.of(context).viewInsets.bottom + 2.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'New Leave Request',
                      style: GoogleFonts.dmSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildStudentInfo(),
                SizedBox(height: 2.h),
                _buildLabel('Leave Type'),
                SizedBox(height: 0.8.h),
                _buildLeaveTypeSelector(),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('From Date'),
                          SizedBox(height: 0.8.h),
                          _buildPickerButton(
                            _formatDate(_fromDate),
                            Icons.calendar_today_rounded,
                            () => _pickDate(true),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('To Date'),
                          SizedBox(height: 0.8.h),
                          _buildPickerButton(
                            _formatDate(_toDate),
                            Icons.calendar_today_rounded,
                            () => _pickDate(false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Departure Time'),
                          SizedBox(height: 0.8.h),
                          _buildPickerButton(
                            _formatTime(_departureTime),
                            Icons.access_time_rounded,
                            () => _pickTime(true),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Arrival Time'),
                          SizedBox(height: 0.8.h),
                          _buildPickerButton(
                            _formatTime(_arrivalTime),
                            Icons.access_time_filled_rounded,
                            () => _pickTime(false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    _buildLabel('Reason for Leave'),
                    const SizedBox(width: 4),
                    Text(
                      '*',
                      style: GoogleFonts.dmSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.error.withAlpha(60)),
                      ),
                      child: Text(
                        'REQUIRED',
                        style: GoogleFonts.dmSans(
                          fontSize: 7.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.8.h),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.studentAccent.withAlpha(18),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppTheme.studentAccent.withAlpha(50)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.studentAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please enter a clear and valid reason for your leave (e.g. Want to go visit home, Family Function, Medical Emergency). Your Class Mam, HOD & Warden will review this.',
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0F172A),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: GoogleFonts.dmSans(fontSize: 12.sp),
                  decoration: InputDecoration(
                    hintText: 'e.g. Want to go visit home...',
                    hintStyle: GoogleFonts.dmSans(
                      color: AppTheme.textSecondary.withAlpha(150),
                      fontSize: 11.5.sp,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: AppTheme.studentAccent, width: 1.8),
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.studentAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    child: Text(
                      'Submit Leave Request',
                      style: GoogleFonts.dmSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.studentAccent.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.studentAccent.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.studentAccent.withAlpha(38),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.studentAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.studentName?.isNotEmpty == true ? widget.studentName! : 'Student',
                style: GoogleFonts.dmSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                widget.rollNo?.isNotEmpty == true ? 'ERP No: ${widget.rollNo}' : 'Hostel Student',
                style: GoogleFonts.dmSans(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildLeaveTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _leaveTypes.map((type) {
        final selected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.studentAccent
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: selected
                    ? AppTheme.studentAccent
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Text(
              type,
              style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPickerButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.studentAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
