import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

const _primaryBlue = Color(0xFF1976D2);

class VoiceTaskDraft {
  const VoiceTaskDraft({
    required this.title,
    required this.description,
    required this.richTextJson,
  });

  final String title;
  final String description;
  final String richTextJson;
}

class VoiceTaskView extends StatefulWidget {
  const VoiceTaskView({required this.onSave, this.speech, super.key});

  final ValueChanged<VoiceTaskDraft> onSave;
  final SpeechToText? speech;

  @override
  State<VoiceTaskView> createState() => _VoiceTaskViewState();
}

class _VoiceTaskViewState extends State<VoiceTaskView> {
  late final SpeechToText _speech;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode(debugLabel: 'voice-task-content');

  bool _speechReady = false;
  bool _isPreparingSpeech = false;
  bool _isListening = false;
  bool _canPop = false;
  bool _isClosing = false;
  String _contentBeforeListening = '';

  @override
  void initState() {
    super.initState();
    _speech = widget.speech ?? SpeechToText();
  }

  @override
  void dispose() {
    unawaited(_speech.cancel());
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _prepareSpeech() async {
    if (_speechReady) return true;
    if (_isPreparingSpeech) return false;
    setState(() => _isPreparingSpeech = true);
    try {
      final available = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
        options: [SpeechToText.androidNoBluetooth],
      );
      if (!mounted) return false;
      setState(() => _speechReady = available);
      if (!available) {
        _showMessage(
          'Thiết bị hoặc trình duyệt này chưa hỗ trợ nhận dạng giọng nói.',
        );
      }
      return available;
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể mở micro. Hãy kiểm tra quyền truy cập micro.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _isPreparingSpeech = false);
    }
  }

  Future<String?> _vietnameseLocale() async {
    // The Web Speech API accepts BCP-47 locale tags but does not expose its
    // complete locale list. Force Vietnamese instead of silently using the
    // browser's (often English) default language.
    if (kIsWeb) return 'vi-VN';

    final locales = await _speech.locales();
    for (final locale in locales) {
      final id = locale.localeId.toLowerCase().replaceAll('-', '_');
      if (id == 'vi_vn') return locale.localeId;
    }
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('vi')) {
        return locale.localeId;
      }
    }
    return null;
  }

  Future<void> _toggleListening() async {
    if (_isPreparingSpeech) return;
    if (_isListening || _speech.isListening) {
      await _speech.stop();
      _finishListening();
      return;
    }

    if (!await _prepareSpeech()) return;
    final localeId = await _vietnameseLocale();
    _contentBeforeListening = _contentController.text.trim();
    if (!mounted) return;
    setState(() => _isListening = true);

    try {
      await _speech.listen(
        onResult: _handleSpeechResult,
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: true,
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(minutes: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isListening = false);
      _showMessage('Không thể bắt đầu nhận dạng giọng nói.');
    }
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final recognized = result.recognizedWords.trim();
    final combined = [
      if (_contentBeforeListening.isNotEmpty) _contentBeforeListening,
      if (recognized.isNotEmpty) recognized,
    ].join(_contentBeforeListening.isEmpty ? '' : '\n');

    _contentController.value = TextEditingValue(
      text: combined,
      selection: TextSelection.collapsed(offset: combined.length),
    );
    setState(() {});
    if (result.finalResult) _finishListening();
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _finishListening();
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() => _isListening = false);
    debugPrint(
      'Speech recognition error: ${error.errorMsg} '
      '(permanent: ${error.permanent})',
    );

    final code = error.errorMsg.toLowerCase();
    if (code == 'no-speech' ||
        code == 'error_no_match' ||
        code == 'error_speech_timeout') {
      _showMessage(
        'Không nghe thấy giọng nói. Hãy kiểm tra đúng micro đầu vào rồi thử lại.',
      );
    } else if (code == 'audio-capture' || code == 'error_audio_error') {
      _showMessage(
        'Edge không nhận được tín hiệu micro. Hãy kiểm tra thiết bị đầu vào.',
      );
    } else if (code == 'not-allowed' ||
        code == 'service-not-allowed' ||
        code == 'error_permission' ||
        error.permanent) {
      _showMessage(
        'Micro chưa được cấp quyền. Hãy cho phép micro trong Edge và Windows.',
      );
    } else if (code == 'network' ||
        code == 'error_network' ||
        code == 'error_network_timeout' ||
        code == 'error_server' ||
        code == 'error_server_disconnected') {
      _showMessage(
        'Dịch vụ nhận dạng giọng nói đang lỗi mạng. Hãy kiểm tra Internet.',
      );
    } else if (code == 'language-not-supported' ||
        code == 'error_language_not_supported' ||
        code == 'error_language_unavailable') {
      _showMessage('Thiết bị này chưa hỗ trợ nhận dạng tiếng Việt.');
    } else if (code == 'aborted' || code == 'error_client') {
      _showMessage('Phiên nghe đã bị hủy. Hãy nhấn micro và thử lại.');
    } else {
      _showMessage('Nhận dạng giọng nói bị gián đoạn (${error.errorMsg}).');
    }
  }

  void _finishListening() {
    if (!mounted || !_isListening) return;
    setState(() => _isListening = false);
  }

  void _save() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _showMessage('Hãy nói hoặc nhập nội dung để lưu.');
      return;
    }
    widget.onSave(
      VoiceTaskDraft(
        title: _titleController.text.trim(),
        description: content,
        richTextJson: jsonEncode([
          {'insert': '$content\n'},
        ]),
      ),
    );
    _closePage();
  }

  Future<void> _handleBack() async {
    if (_isClosing) return;
    if (_speech.isListening) await _speech.stop();
    if (_contentController.text.trim().isNotEmpty) {
      _save();
    } else {
      _closePage();
    }
  }

  void _closePage() {
    if (_isClosing) return;
    _isClosing = true;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? const Color(0xFF172A3A)
        : const Color(0xFFF0F8FF);
    final mutedColor = isDark
        ? const Color(0xFFA8C1D4)
        : const Color(0xFF6F8192);

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text(
            'Ghi chú giọng nói',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            FilledButton(
              key: const Key('save_voice_task_button'),
              onPressed: _isListening ? null : _save,
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primaryBlue,
                disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('voice_task_title_field'),
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tiêu đề',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    key: const Key('voice_task_content_field'),
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    readOnly: _isListening,
                    textCapitalization: TextCapitalization.sentences,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'TDL đang nghe bạn nói...'
                          : 'Nội dung bạn nói sẽ xuất hiện ở đây.',
                      filled: true,
                      fillColor: panelColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isListening
                      ? 'Đang nghe… Nhấn micro để dừng.'
                      : 'Nhấn micro và bắt đầu nói nội dung ghi chú.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isListening ? _primaryBlue : mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Semantics(
                    button: true,
                    label: _isListening ? 'Dừng ghi âm' : 'Bắt đầu ghi âm',
                    child: InkWell(
                      key: const Key('voice_microphone_button'),
                      onTap: _toggleListening,
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? const Color(0xFFE74C4C)
                              : _primaryBlue,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isListening
                                          ? const Color(0xFFE74C4C)
                                          : _primaryBlue)
                                      .withValues(alpha: 0.28),
                              blurRadius: 16,
                              spreadRadius: _isListening ? 5 : 2,
                            ),
                          ],
                        ),
                        child: _isPreparingSpeech
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                _isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
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
}
