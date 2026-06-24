import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/report_service.dart';

class ReportDialog extends ConsumerStatefulWidget {
  final String reportedItemId;
  final String itemType;

  const ReportDialog({
    Key? key,
    required this.reportedItemId,
    required this.itemType,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {required String reportedItemId, required String itemType}) {
    return showDialog(
      context: context,
      builder: (context) => ReportDialog(reportedItemId: reportedItemId, itemType: itemType),
    );
  }

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  final _reasonController = TextEditingController();
  final _commentsController = TextEditingController();

  final List<String> _commonReasons = [
    'Spam or misleading',
    'Abusive or harmful',
    'Inappropriate content',
    'Fraudulent',
    'Other'
  ];
  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  void _submitReport() {
    final reason = _selectedReason ?? _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a reason')),
      );
      return;
    }

    final comments = _commentsController.text.trim();
    final currentContext = context;

    // Optimistic UI Update: instantly close and notify success
    Navigator.of(context).pop();
    ScaffoldMessenger.of(currentContext).showSnackBar(
      const SnackBar(content: Text('Report submitted successfully')),
    );

    // Fire API request in background without blocking UI
    final reportService = ref.read(reportServiceProvider);
    reportService.submitReport(
      reportedItemId: widget.reportedItemId,
      itemType: widget.itemType,
      reason: reason,
      comments: comments.isNotEmpty ? comments : null,
    ).catchError((e) {
      // Ignore background errors or log them if necessary
      debugPrint('Background report submission failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this?'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              hint: const Text('Select a reason'),
              items: _commonReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) {
                setState(() => _selectedReason = val);
              },
            ),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Custom Reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Additional Comments (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitReport,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
