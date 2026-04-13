import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/task_model.dart';
import '../models/schedule_analysis.dart';

class AiScheduleService extends ChangeNotifier{
  ScheduleAnalysis? _currentAnalysis;

  bool _isLoading = false;
  String? _errorMessage;

final String _apiKey = '';

  ScheduleAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage; 

Future<void> analyzeSchedule(List<TaskModel> tasks) async {
  if (_apiKey.isEmpty || tasks.isEmpty) return;
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
     apiKey: _apiKey,
     );

      final tasksJson = jsonEncode (tasks.map((t) => t.toJson()).toList());


      final prompt = ''' 

      You are an expert students scheduling assistant. The user has provided the ff tasks for their day in JSON format: $tasksJson

      Please provide exactly 4 sections of markdown text:
      1 ### Detected Conflicts 
      Lists any scheduling conflicts 
      2. ### Ranked Tasks
      Rank which tasks need attention first.
      3.### recommend Schedule 
      Provide a revised daily timelien view adjusting the tasks time.
      4.### Explanation
      Explain why this recommendation was made.
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      
      _currentAnalysis = _parseResponse(response.text?? '');
    } catch (e) {
      _errorMessage = 'Failed $e';
    }finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ScheduleAnalysis _parseResponse(String fullText) {
    String conflicts = "", rankedTasks = "", recommendedSchedule = "", explanation = "";

    final sections = fullText.split('###');
    for (var section in sections) {
      if (section.startsWith('Detected Conflicts')) conflicts = section.replaceFirst('Detected Conflicts' ,'').trim();
      else if (section.startsWith('Ranked Tasks')) rankedTasks = section.replaceFirst('Ranked Tasks', '').trim();
      else if (section.startsWith('Recommended Schedule')) recommendedSchedule = section.replaceFirst('Recommended Schedule', '').trim();
      else if (section.startsWith('Explanation')) explanation = section.replaceFirst('Explanation', '').trim();


    }
    return ScheduleAnalysis(
      conflicts: conflicts,
      rankedTasks: rankedTasks,
      recommendedSchedule: recommendedSchedule,
      explanation: explanation,
    );
  }

}