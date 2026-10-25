import '../data/emergency_data.dart';
import '../models/emergency_model.dart';

class DecisionEngine {
  AssessmentQuestion getInitialQuestion() {
    return triageQuestions['q_responsive']!;
  }

  AssessmentQuestion? getNextQuestion(String currentQuestionId, bool userSaidYes) {
    final currentQuestion = triageQuestions[currentQuestionId];
    if (currentQuestion == null) return null;

    final nextId = userSaidYes
        ? currentQuestion.yesNextQuestionId
        : currentQuestion.noNextQuestionId;

    if (nextId != null && triageQuestions.containsKey(nextId)) {
      return triageQuestions[nextId];
    }
    return null;
  }

  EmergencyType? evaluateEmergencyOutcome(String currentQuestionId, bool userSaidYes) {
    final currentQuestion = triageQuestions[currentQuestionId];
    if (currentQuestion == null) return null;

    return userSaidYes
        ? currentQuestion.yesResultEmergency
        : currentQuestion.noResultEmergency;
  }

  List getProtocolForType(EmergencyType type) {
    switch (type) {
      case EmergencyType.cprAdult:
        return adultCprProtocol;
      case EmergencyType.chokingAdult:
        return adultChokingProtocol;
      default:
        return adultChokingProtocol;
    }
  }
}