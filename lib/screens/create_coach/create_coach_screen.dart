import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/providers/coach_provider.dart';
import 'package:my_aicoach/providers/subscription_provider.dart';

class CreateCoachScreen extends StatefulWidget {
  const CreateCoachScreen({super.key});

  @override
  State<CreateCoachScreen> createState() => _CreateCoachScreenState();
}

class _CreateCoachScreenState extends State<CreateCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _domainController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _boundariesController = TextEditingController();
  int _currentStep = 0;
  bool _isLoading = false;
  String _selectedTone = 'Professional';
  bool _enableWebSearch = false;
  String _generatedPrompt = '';

  static const List<String> _toneOptions = [
    'Professional',
    'Friendly',
    'Direct',
    'Empathetic',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _domainController.dispose();
    _expertiseController.dispose();
    _boundariesController.dispose();
    super.dispose();
  }

  String _buildSystemPrompt() {
    final name = _nameController.text.trim();
    final domain = _domainController.text.trim();
    final expertise = _expertiseController.text.trim();
    final boundaries = _boundariesController.text.trim();
    final tone = _selectedTone.toLowerCase();

    final buffer = StringBuffer();
    buffer.write(
        'You are $name, a highly specialized $tone coach in a private one-on-one session. ');
    buffer.write('Your area of expertise is: $domain. ');

    if (expertise.isNotEmpty) {
      buffer.write('You have deep knowledge in: $expertise. ');
    }

    buffer.write(
        'You adapt your language to match the user\'s level and always ask about their specific situation before giving advice. ');

    if (boundaries.isNotEmpty) {
      buffer.write(
          'IMPORTANT: You must NOT discuss the following topics: $boundaries. '
          'If the user asks about these topics, politely explain that they fall outside your expertise and suggest they consult an appropriate specialist, then redirect the conversation back to your domain. ');
    }

    buffer.write(
        'If the user asks about topics clearly outside your domain of $domain, '
        'politely redirect them by explaining your specialty and suggesting they consult an appropriate expert. '
        'Keep responses to 2-3 short paragraphs. End with one focused follow-up question.');

    return buffer.toString();
  }

  Future<void> _createCoach() async {
    setState(() => _isLoading = true);

    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final subProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);

      await db.into(db.coaches).insert(
            CoachesCompanion(
              name: Value(_nameController.text.trim()),
              description: Value(
                  '$_selectedTone coach specializing in ${_domainController.text.trim()}.'),
              systemPrompt: Value(_generatedPrompt),
              isCustom: const Value(true),
              isPremium: const Value(false),
              enableWebSearch: Value(_enableWebSearch),
            ),
          );

      // Track trial usage
      if (subProvider.tier == SubscriptionTier.trial) {
        await subProvider.incrementTrialCoachCount();
      }

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
          const SnackBar(
              content: Text('Could not create coach. Please try again.')),
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
            if (_currentStep == 0) {
              if (_nameController.text.trim().isEmpty ||
                  _domainController.text.trim().isEmpty) {
                _formKey.currentState?.validate();
                return;
              }
            }
            if (_currentStep == 1) {
              if (_expertiseController.text.trim().isEmpty) {
                _formKey.currentState?.validate();
                return;
              }
            }
            if (_currentStep < 2) {
              if (_currentStep == 1) {
                _generatedPrompt = _buildSystemPrompt();
              }
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
                        : Text(_currentStep == 2 ? 'Create Coach' : 'Next'),
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
            // Step 1: Identity
            Step(
              title: const Text('Identity'),
              subtitle: const Text('Name, domain & tone'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Coach Name',
                      hintText: 'e.g., Crypto Advisor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _domainController,
                    decoration: const InputDecoration(
                      labelText: 'Specialty Domain',
                      hintText: 'e.g., cryptocurrency trading, yoga, UX design',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a specialty domain';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Coaching Tone', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _toneOptions.map((tone) {
                      final selected = _selectedTone == tone;
                      return ChoiceChip(
                        label: Text(tone),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedTone = tone),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Step 2: Expertise & Boundaries
            Step(
              title: const Text('Expertise & Boundaries'),
              subtitle: const Text('What they know & what they refuse'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _expertiseController,
                    decoration: const InputDecoration(
                      labelText: 'What should this coach be an expert in?',
                      hintText:
                          'e.g., technical analysis, candlestick patterns, risk management, portfolio diversification',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe the expertise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _boundariesController,
                    decoration: const InputDecoration(
                      labelText: 'Topics to refuse (optional)',
                      hintText:
                          'e.g., medical advice, legal counsel, specific stock picks',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // Step 3: Review & Fine-Tune
            Step(
              title: const Text('Review & Settings'),
              subtitle: const Text('Fine-tune and enable features'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Generated System Prompt',
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    'This was auto-generated from your inputs. You can edit it for advanced fine-tuning.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _generatedPrompt,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 6,
                    style: theme.textTheme.bodySmall,
                    onChanged: (value) => _generatedPrompt = value,
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Web Search'),
                    subtitle: const Text(
                        'Coach can search the internet for up-to-date information'),
                    secondary: Icon(Icons.language,
                        color: _enableWebSearch
                            ? theme.colorScheme.primary
                            : null),
                    value: _enableWebSearch,
                    onChanged: (value) =>
                        setState(() => _enableWebSearch = value),
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
