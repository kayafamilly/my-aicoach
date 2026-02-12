import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_aicoach/services/speech_service.dart';
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/config/routes.dart';
import 'package:my_aicoach/providers/chat_provider.dart';
import 'package:my_aicoach/providers/subscription_provider.dart';
import 'package:my_aicoach/providers/calendar_provider.dart';
import 'package:my_aicoach/services/file_extraction_service.dart';
import 'package:my_aicoach/services/notification_service.dart';
import 'package:my_aicoach/widgets/message_bubble.dart';
import 'package:my_aicoach/services/permission_service.dart';
import 'package:my_aicoach/widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Coach _coach;
  late int _conversationId;
  bool _initialized = false;
  int _previousMessageCount = 0;

  // Feature toggles for next message
  bool _webSearchForNextMessage = false;
  String? _pendingImagePath;
  String? _pendingFileContext;
  String? _pendingFileName;

  // Speech-to-text (record + Gemini transcription)
  bool _isRecording = false;
  bool _isTranscribing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _coach = args['coach'] as Coach;
      _conversationId = args['conversationId'] as int;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ChatProvider>(context, listen: false)
            .loadMessages(_conversationId);
      });
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _canUseFeatures() {
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    return sub.canUseAdvancedFeatures(_coach.isCustom);
  }

  void _showPaywall() {
    Navigator.pushNamed(context, AppRoutes.paywall, arguments: 'features');
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty &&
        _pendingImagePath == null &&
        _pendingFileContext == null) {
      return;
    }

    final useWebSearch = _webSearchForNextMessage || _coach.enableWebSearch;
    final imagePath = _pendingImagePath;
    final fileContext = _pendingFileContext;
    final fileName = _pendingFileName;

    // Build the actual message content — prepend file indicator if file attached
    String messageContent = content;
    if (fileName != null) {
      messageContent = content.isEmpty
          ? 'Analyze this file: $fileName'
          : '$content\n[Attached file: $fileName]';
    }

    // Get calendar context if connected
    String? calendarContext;
    try {
      final calProvider = Provider.of<CalendarProvider>(context, listen: false);
      if (calProvider.isConnected) {
        calendarContext = calProvider.getCalendarContext();
      }
    } catch (_) {}

    _messageController.clear();
    setState(() {
      _pendingImagePath = null;
      _pendingFileContext = null;
      _pendingFileName = null;
    });

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(
      conversationId: _conversationId,
      content: messageContent,
      systemPrompt: _coach.systemPrompt,
      enableWebSearch: useWebSearch,
      imagePath: imagePath,
      fileContext: fileContext,
      calendarContext: calendarContext,
    );
  }

  // ── Speech-to-text (record + Gemini transcription) ──
  Future<void> _toggleRecording() async {
    if (!_canUseFeatures()) {
      _showPaywall();
      return;
    }

    if (_isRecording) {
      // Stop recording → transcribe → auto-send
      setState(() => _isRecording = false);
      final audioPath = await SpeechService.stopRecording();
      if (audioPath == null) return;

      setState(() => _isTranscribing = true);
      final transcription = await SpeechService.transcribe(audioPath);
      setState(() => _isTranscribing = false);

      if (transcription != null && transcription.isNotEmpty && mounted) {
        // Auto-send the transcription as a message
        final useWebSearch = _webSearchForNextMessage || _coach.enableWebSearch;
        String? calendarContext;
        try {
          final calProvider =
              Provider.of<CalendarProvider>(context, listen: false);
          if (calProvider.isConnected) {
            calendarContext = calProvider.getCalendarContext();
          }
        } catch (_) {}

        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.sendMessage(
          conversationId: _conversationId,
          content: transcription,
          systemPrompt: _coach.systemPrompt,
          enableWebSearch: useWebSearch,
          calendarContext: calendarContext,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not transcribe audio. Try again.')),
        );
      }
    } else {
      // Start recording
      if (!mounted) return;
      final micGranted = await PermissionService.requestMicrophone(context);
      if (!micGranted) return;

      final started = await SpeechService.startRecording();
      if (started) {
        setState(() => _isRecording = true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start recording')),
        );
      }
    }
  }

  // ── Image picker ──
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pendingImagePath = picked.path);
    }
  }

  // ── File picker ──
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'csv',
        'txt',
        'md',
        'doc',
        'docx',
        'xls',
        'xlsx'
      ],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;
      final text = await FileExtractionService.extractText(path);
      if (text != null && text.isNotEmpty) {
        setState(() {
          _pendingFileContext = text;
          _pendingFileName = name;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not extract text from this file')),
          );
        }
      }
    }
  }

  // ── Reminder dialog ──
  Future<void> _showReminderDialog() async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Set a Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Reminder message',
                  hintText: 'e.g. Review my action plan',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        selectedTime.hour,
                        selectedTime.minute));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(selectedTime.format(ctx)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setDialogState(() {
                      selectedTime = time;
                      selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          time.hour,
                          time.minute);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Set Reminder')),
          ],
        ),
      ),
    );

    if (confirmed == true && titleController.text.isNotEmpty) {
      if (!mounted) return;
      final notifGranted = await PermissionService.requestNotification(context);
      if (!notifGranted) return;
      await NotificationService.scheduleReminder(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Coach Reminder',
        body: titleController.text,
        scheduledTime: selectedDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Reminder set for ${selectedTime.format(context)}')),
        );
      }
    }
    titleController.dispose();
  }

  // ── Calendar bottom sheet ──
  Future<void> _showCalendarSheet() async {
    final calProvider = Provider.of<CalendarProvider>(context, listen: false);

    if (!calProvider.isConnected) {
      final connected = await calProvider.connect();
      if (!connected) {
        if (mounted) {
          final err =
              calProvider.lastError ?? 'Could not connect to Google Calendar';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), duration: const Duration(seconds: 5)),
          );
        }
        return;
      }
    }

    await calProvider.refreshEvents();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final events = calProvider.todayEvents;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text("Today's Schedule",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No events today'),
                  )
                else
                  ...events.take(5).map((e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: Text(e.summary ?? 'Untitled'),
                        subtitle: Text(
                          e.start?.dateTime != null
                              ? '${e.start!.dateTime!.hour}:${e.start!.dateTime!.minute.toString().padLeft(2, '0')}'
                              : 'All day',
                        ),
                      )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddEventDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Event'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Add calendar event dialog ──
  Future<void> _showAddEventDialog() async {
    final titleController = TextEditingController();
    DateTime startDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay startTime = TimeOfDay.fromDateTime(startDate);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Calendar Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event title'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                    '${startDate.day}/${startDate.month}/${startDate.year}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() => startDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        startTime.hour,
                        startTime.minute));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(startTime.format(ctx)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: startTime,
                  );
                  if (time != null) {
                    setDialogState(() {
                      startTime = time;
                      startDate = DateTime(startDate.year, startDate.month,
                          startDate.day, time.hour, time.minute);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Create')),
          ],
        ),
      ),
    );

    if (confirmed == true && titleController.text.isNotEmpty && mounted) {
      final calProvider = Provider.of<CalendarProvider>(context, listen: false);
      await calProvider.createEvent(
        summary: titleController.text,
        start: startDate,
        end: startDate.add(const Duration(hours: 1)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created')),
        );
      }
    }
    titleController.dispose();
  }

  // ── "+" menu ──
  void _showChatOptions() {
    final hasAdvanced = _canUseFeatures();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Web search
                ListTile(
                  leading: Icon(Icons.travel_explore,
                      color: _webSearchForNextMessage
                          ? theme.colorScheme.primary
                          : null),
                  title: const Text('Search on internet'),
                  subtitle: Text(_webSearchForNextMessage
                      ? 'Enabled for next message'
                      : 'Your coach will search the web'),
                  trailing: _webSearchForNextMessage
                      ? Icon(Icons.check_circle,
                          color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() =>
                        _webSearchForNextMessage = !_webSearchForNextMessage);
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1),
                // Attach image
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Attach image'),
                  subtitle:
                      const Text('Send a photo for your coach to analyze'),
                  trailing:
                      !hasAdvanced ? const Icon(Icons.lock, size: 18) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!hasAdvanced) {
                      _showPaywall();
                      return;
                    }
                    _showImageSourceDialog();
                  },
                ),
                const Divider(height: 1),
                // Attach file
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: const Text('Attach file'),
                  subtitle: const Text('PDF, CSV, TXT, DOCX, XLS'),
                  trailing:
                      !hasAdvanced ? const Icon(Icons.lock, size: 18) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!hasAdvanced) {
                      _showPaywall();
                      return;
                    }
                    _pickFile();
                  },
                ),
                const Divider(height: 1),
                // My Calendar
                ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('My Calendar'),
                  subtitle: const Text('View schedule & add events'),
                  trailing:
                      !hasAdvanced ? const Icon(Icons.lock, size: 18) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!hasAdvanced) {
                      _showPaywall();
                      return;
                    }
                    _showCalendarSheet();
                  },
                ),
                const Divider(height: 1),
                // Set a reminder
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Set a reminder'),
                  subtitle: const Text('Schedule a local notification'),
                  trailing:
                      !hasAdvanced ? const Icon(Icons.lock, size: 18) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!hasAdvanced) {
                      _showPaywall();
                      return;
                    }
                    _showReminderDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attach Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final granted = await PermissionService.requestCamera(context);
                if (!granted) return;
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    // Only scroll to bottom when new messages arrive
    final currentCount = chatProvider.messages.length;
    if (currentCount > _previousMessageCount || chatProvider.isTyping) {
      _previousMessageCount = currentCount;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    // Show search warning snackbar if web search failed
    if (chatProvider.searchWarning != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Web search failed: ${chatProvider.searchWarning}')),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          chatProvider.clearSearchWarning();
        }
      });
    }

    final hasText = _messageController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(_coach.name, overflow: TextOverflow.ellipsis),
            ),
            if (_coach.enableWebSearch) ...[
              const SizedBox(width: 8),
              Icon(Icons.language, size: 16, color: theme.colorScheme.primary),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text(
                      'Are you sure you want to clear all messages?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear')),
                  ],
                ),
              );
              if (confirm == true) {
                await chatProvider.clearHistory(_conversationId);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatProvider.messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 64,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'Start your coaching session',
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ask ${_coach.name} anything!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.7)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: chatProvider.messages.length +
                            (chatProvider.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatProvider.messages.length &&
                              chatProvider.isTyping) {
                            return TypingIndicator(
                                isSearching: chatProvider.isSearching);
                          }
                          return MessageBubble(
                              message: chatProvider.messages[index]);
                        },
                      ),
          ),
          if (chatProvider.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(chatProvider.error!,
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer))),
                ],
              ),
            ),
          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active attachment chips
                  if (_webSearchForNextMessage ||
                      _pendingImagePath != null ||
                      _pendingFileName != null ||
                      _isRecording ||
                      _isTranscribing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (_webSearchForNextMessage)
                            _buildChip(
                              icon: Icons.travel_explore,
                              label: 'Web search',
                              onRemove: () => setState(
                                  () => _webSearchForNextMessage = false),
                            ),
                          if (_pendingImagePath != null)
                            _buildChip(
                              icon: Icons.image,
                              label: 'Image attached',
                              onRemove: () =>
                                  setState(() => _pendingImagePath = null),
                            ),
                          if (_pendingFileName != null)
                            _buildChip(
                              icon: Icons.attach_file,
                              label: _pendingFileName!,
                              onRemove: () => setState(() {
                                _pendingFileContext = null;
                                _pendingFileName = null;
                              }),
                            ),
                          if (_isRecording)
                            _buildChip(
                              icon: Icons.mic,
                              label: 'Recording...',
                              color: Colors.red,
                              onRemove: _toggleRecording,
                            ),
                          if (_isTranscribing)
                            _buildChip(
                              icon: Icons.auto_awesome,
                              label: 'Transcribing...',
                              color: Colors.orange,
                              onRemove: () {},
                            ),
                        ],
                      ),
                    ),
                  // Image preview
                  if (_pendingImagePath != null)
                    Container(
                      height: 100,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pendingImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  // Input row
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            chatProvider.isTyping ? null : _showChatOptions,
                        icon: const Icon(Icons.add_circle_outline),
                        color: theme.colorScheme.primary,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _isRecording
                                ? 'Recording... tap mic to stop'
                                : _isTranscribing
                                    ? 'Transcribing...'
                                    : 'Type your message...',
                            filled: true,
                            fillColor:
                                theme.colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: (_) => setState(() {}),
                          enabled: !chatProvider.isTyping,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (chatProvider.isTyping)
                        const FloatingActionButton(
                          onPressed: null,
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else if (_isTranscribing)
                        const FloatingActionButton(
                          onPressed: null,
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else if (!hasText && _pendingImagePath == null)
                        FloatingActionButton(
                          onPressed: _toggleRecording,
                          backgroundColor: _isRecording
                              ? Colors.red
                              : theme.colorScheme.primaryContainer,
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: _isRecording
                                ? Colors.white
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      else
                        FloatingActionButton(
                          onPressed: _sendMessage,
                          child: const Icon(Icons.send),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label.length > 20 ? '${label.substring(0, 20)}...' : label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: color ?? theme.colorScheme.primary),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close,
                size: 14, color: color ?? theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
