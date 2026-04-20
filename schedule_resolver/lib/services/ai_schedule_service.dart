import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/task_model.dart';
import '../models/schedule_analysis.dart';

class AiScheduleService extends ChangeNotifier {
  ScheduleAnalysis? _currentAnalysis;

  bool _isLoading = false;
  String? _errorMessage;

  final String _apiKey = 'AIzaSyDyJ-Qnab1S_93F5tLkFhxCBQMzxxu1Lrc';

  ScheduleAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeSchedule(List<TaskModel> tasks) async {
    if (_apiKey.isEmpty || tasks.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

      final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());

      final prompt =
          '''
      You are an expert students scheduling assistant. Use plain text with formatting:

      Tasks JSON: $tasksJson

      EXACTLY 4 sections separated by ###:

      ### Detected Conflicts
      Use bullet points (• or -) for each conflict.

      ### Ranked Tasks
      Numbered list: 1. Task name... 2. Task name...

      ### Recommended Schedule
      Neat timeline format, each on new line:
      8:00-9:00: Task (reason)

      ### Explanation
      Numbered reasons or bullet points explaining changes.
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      _currentAnalysis = _parseResponse(response.text ?? '');
    } catch (e) {
      _errorMessage = 'Failed $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ScheduleAnalysis _parseResponse(String fullText) {
    String conflicts = "";
    String rankedTasks = "";
    String recommendedSchedule = "";
    String explanation = "";

    final sections = fullText.split('###');

    for (var section in sections) {
      section = section.trim();

      if (section.startsWith('Detected Conflicts')) {
        conflicts = section
            .replaceFirst('Detected Conflicts', '')
            .trim();
      } else if (section.startsWith('Ranked Tasks')) {
        rankedTasks = section
            .replaceFirst('Ranked Tasks', '')
            .trim();
      } else if (section.startsWith('Recommended Schedule') ||
          section.startsWith('recommend Schedule')) {
        recommendedSchedule = section
            .replaceFirst('Recommended Schedule', '')
            .replaceFirst('recommend Schedule', '')
            .trim();
      } else if (section.startsWith('Explanation')) {
        explanation = section
            .replaceFirst('Explanation', '')
            .trim();
      }
    }

    // Clean markdown but keep newlines and bullets/numbers
    conflicts = conflicts.replaceAll('*', '').replaceAll('#', '').replaceAll('**', '').trim();
    rankedTasks = rankedTasks.replaceAll('*', '').replaceAll('#', '').replaceAll('**', '').trim();
    recommendedSchedule = recommendedSchedule.replaceAll('*', '').replaceAll('#', '').replaceAll('**', '').trim();
    explanation = explanation.replaceAll('*', '').replaceAll('#', '').replaceAll('**', '').trim();

    return ScheduleAnalysis(
      conflicts: conflicts,
      rankedTasks: rankedTasks,
      recommendedSchedule: recommendedSchedule,
      explanation: explanation,
    );
  }
}
