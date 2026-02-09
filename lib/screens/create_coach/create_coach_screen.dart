import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aicoach/services/coach_service.dart';
import 'package:my_aicoach/providers/coach_provider.dart';

class CreateCoachScreen extends StatefulWidget {
  const CreateCoachScreen({super.key});

  @override
  State<CreateCoachScreen> createState() => _CreateCoachScreenState();
}

class _CreateCoachScreenState extends State<CreateCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _createCoach() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final coachService = Provider.of<CoachService>(context, listen: false);
      await coachService.createCustomCoach(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        systemPrompt: _systemPromptController.text.trim(),
      );

      if (mounted) {
        Provider.of<CoachProvider>(context, listen: false).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coach created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating coach: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Coach'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            // Validate current step before advancing
            if (_currentStep == 0 && (_nameController.text.trim().isEmpty)) {
              _formKey.currentState?.validate();
              return;
            }
            if (_currentStep == 1 &&
                (_descriptionController.text.trim().isEmpty)) {
              _formKey.currentState?.validate();
              return;
            }
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _createCoach();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_currentStep == 2 ? 'Create' : 'Next'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isLoading ? null : details.onStepCancel,
                    child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Name'),
              subtitle: const Text('Give your coach a name'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Coach Name',
                  hintText: 'e.g., Productivity Coach',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
            ),
            Step(
              title: const Text('Description'),
              subtitle: const Text('What does this coach do?'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what this coach helps with...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ),
            Step(
              title: const Text('Coaching Style'),
              subtitle: const Text('Define the AI personality'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Prompt',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This defines how your coach will respond. Be specific about the tone, expertise, and approach.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _systemPromptController,
                    decoration: const InputDecoration(
                      hintText: 'You are a helpful coach who specializes in...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a system prompt';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
