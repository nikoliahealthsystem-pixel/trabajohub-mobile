import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart'; // Assuming you have this
import '../state/survey_notifier.dart';
import 'widgets/survey_question_widget.dart';

class SurveyScreen extends ConsumerStatefulWidget {
  final String shiftId;
  final String visitId;

  const SurveyScreen({
    super.key,
    required this.shiftId,
    required this.visitId,
  });

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSurvey();
    });
  }

  Future<void> _loadSurvey() async {
    await ref
        .read(surveyNotifierProvider(widget.shiftId).notifier)
        .loadSurvey(widget.shiftId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(surveyNotifierProvider(widget.shiftId));
    final notifier = ref.read(surveyNotifierProvider(widget.shiftId).notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(context, state),
          Expanded(
            child: _buildBody(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SurveyState state) {
    final answeredCount = state.answers.values.where((a) => a.isNotEmpty).length;
    final totalQuestions = state.survey?.questions.length ?? 0;
    final progress = totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

    return Container(
      width: double.maxFinite,
      decoration: const BoxDecoration(
        gradient: ColorConstants.appGradient,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shift Survey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (state.survey != null) ...[
            const SizedBox(height: 4),
            Text(
              state.survey!.title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            // Progress
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      color: Colors.white,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$answeredCount/$totalQuestions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(SurveyState state, SurveyNotifier notifier) {
    if (state.isLoading) {
      return  Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (state.error != null) {
      // Determine the title based on the error content
      final String title = state.error!.contains("already")
          ? 'Survey Already Submitted'
          : 'Failed to load survey';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(state.error!.contains("already")? Icons.check_circle:Icons.error_outline, size: 64, color:state.error!.contains("already")? Colors.green: Color(0xFFE24B4A)),
              const SizedBox(height: 16),
              Text(
                title, // Uses the dynamic title
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!.contains("already")? "Your Response As Already been Recorded" :state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF536C79)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _loadSurvey,
              ),
            ],
          ),
        ),
      );
    }

    if (state.survey == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Color(0xFF94A3B4)),
            SizedBox(height: 16),
            Text(
              'No survey available',
              style: TextStyle(fontSize: 18, color: Color(0xFF1A2632)),
            ),
          ],
        ),
      );
    }

    final allAnswered = state.survey!.questions.every(
          (q) => state.answers.containsKey(q.id) && state.answers[q.id]!.isNotEmpty,
    );

    return RefreshIndicator(
      color: accentColor,
      onRefresh: _loadSurvey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (state.survey!.description != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Text(
                state.survey!.description!,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF536C79),
                  height: 1.5,
                ),
              ),
            ),

          const SizedBox(height: 20),

          ...state.survey!.questions.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurveyQuestionWidget(
              question: q,
              currentAnswer: state.answers[q.id],
              onAnswerChanged: (answer) =>
                  notifier.updateAnswer(q.id, answer),
            ),
          )),

          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton(
            onPressed: state.isSubmitting || !allAnswered
                ? null
                : () async {
              final success = await notifier.submitSurvey(
                widget.shiftId,
                widget.visitId,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you! Survey submitted successfully.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A7D95),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: state.isSubmitting
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              allAnswered ? 'Submit Survey' : 'Answer all questions to continue',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (state.successMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                state.successMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}