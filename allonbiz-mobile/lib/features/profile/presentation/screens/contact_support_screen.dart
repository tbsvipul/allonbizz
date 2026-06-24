import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/network/api_client.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_bar_binding.dart';
class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _priority = 'Normal';
  bool _isLoading = false;

  Future<void> _submitTicket() async {
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/user/support',
        body: {
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
          'priority': _priority,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Support ticket created successfully. We will get back to you soon.',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit ticket: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBarBinding(
      config: AppBarConfig(
        title: const Text('Contact Support'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.lg,
            AppDimensions.lg,
            AppDimensions.lg,
            140 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.support_agent_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              'How can we help you?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              'Please describe your issue below and our support team will respond as soon as possible.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.xl),

            AppTextField.regular(
              controller: _subjectController,
              label: 'Subject',
              hint: 'Brief description of the issue',
            ),
            const SizedBox(height: AppDimensions.lg),

            DropdownButtonFormField<String>(
              initialValue: _priority,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              dropdownColor: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              decoration: InputDecoration(
                labelText: 'Priority',
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceElevatedDark.withValues(alpha: 0.86)
                    : AppColors.white.withValues(alpha: 0.92),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.72),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.72),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 1.6,
                  ),
                ),
              ),
              items: [
                'Low',
                'Normal',
                'High',
              ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _priority = val);
              },
            ),
            const SizedBox(height: AppDimensions.lg),

            AppTextField.multiline(
              controller: _messageController,
              label: 'Message',
              hint: 'Describe your issue in detail...',
            ),

            const SizedBox(height: AppDimensions.xxl),

            AppButton.primary(
              onPressed: _isLoading ? null : _submitTicket,
              label: _isLoading ? 'Submitting...' : 'Submit Ticket',
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    ));
  }
}
