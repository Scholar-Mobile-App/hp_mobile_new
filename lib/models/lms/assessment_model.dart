import 'package:flutter/foundation.dart';

class AssessmentListResponse {
  final bool status;
  final List<Assessment> data;

  AssessmentListResponse({
    required this.status,
    required this.data,
  });

  factory AssessmentListResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentListResponse(
      status: json['status'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Assessment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'data': data.map((e) => e.toJson()).toList(),
      };
}

class Assessment {
  final int id;
  final int? gradeId;
  final int? standardId;
  final int? subjectId;
  final String? paperName;
  final String? paperDesc;
  final String? openDate;
  final String? closeDate;
  final int? timelimitEnable;
  final int? timeAllowed;
  final int? totalMarks;
  final int? totalQues;
  final String? questionIds;
  final int? shuffleQuestion;
  final String? attemptAllowed;
  final int? showFeedback;
  final int? showHide;
  final int? resultShowAns;
  final String? createdOn;
  final int? createdBy;
  final int? subInstituteId;
  final String? syear;
  final String? examType;
  final int? updatedBy;
  final int? deletedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final List<Question> questions;

  Assessment({
    required this.id,
    this.gradeId,
    this.standardId,
    this.subjectId,
    this.paperName,
    this.paperDesc,
    this.openDate,
    this.closeDate,
    this.timelimitEnable,
    this.timeAllowed,
    this.totalMarks,
    this.totalQues,
    this.questionIds,
    this.shuffleQuestion,
    this.attemptAllowed,
    this.showFeedback,
    this.showHide,
    this.resultShowAns,
    this.createdOn,
    this.createdBy,
    this.subInstituteId,
    this.syear,
    this.examType,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.questions,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'] ?? 0,
      gradeId: json['grade_id'],
      standardId: json['standard_id'],
      subjectId: json['subject_id'],
      paperName: json['paper_name'],
      paperDesc: json['paper_desc'],
      openDate: json['open_date'],
      closeDate: json['close_date'],
      timelimitEnable: json['timelimit_enable'],
      timeAllowed: json['time_allowed'],
      totalMarks: json['total_marks'],
      totalQues: json['total_ques'],
      questionIds: json['question_ids'],
      shuffleQuestion: json['shuffle_question'],
      attemptAllowed: json['attempt_allowed'],
      showFeedback: json['show_feedback'],
      showHide: json['show_hide'],
      resultShowAns: json['result_show_ans'],
      createdOn: json['created_on'],
      createdBy: json['created_by'],
      subInstituteId: json['sub_institute_id'],
      syear: json['syear'],
      examType: json['exam_type'],
      updatedBy: json['updated_by'],
      deletedBy: json['deleted_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'grade_id': gradeId,
        'standard_id': standardId,
        'subject_id': subjectId,
        'paper_name': paperName,
        'paper_desc': paperDesc,
        'open_date': openDate,
        'close_date': closeDate,
        'timelimit_enable': timelimitEnable,
        'time_allowed': timeAllowed,
        'total_marks': totalMarks,
        'total_ques': totalQues,
        'question_ids': questionIds,
        'shuffle_question': shuffleQuestion,
        'attempt_allowed': attemptAllowed,
        'show_feedback': showFeedback,
        'show_hide': showHide,
        'result_show_ans': resultShowAns,
        'created_on': createdOn,
        'created_by': createdBy,
        'sub_institute_id': subInstituteId,
        'syear': syear,
        'exam_type': examType,
        'updated_by': updatedBy,
        'deleted_by': deletedBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'questions': questions.map((e) => e.toJson()).toList(),
      };
}

class Question {
  final int id;
  final int? questionTypeId;
  final int? gradeId;
  final int? standardId;
  final int? subjectId;
  final int? chapterId;
  final String? paperCategory;
  final int? topicId;
  final String? questionTitle;
  final String? description;
  final int? points;
  final int? multipleAnswer;
  final String? concept;
  final String? subconcept;
  final String? preGradeTopic;
  final String? postGradeTopic;
  final String? crossCurriculumGradeTopic;
  final int? subInstituteId;
  final int? status;
  final int? createdBy;
  final String? createdOn;
  final String? answer;
  final String? hintText;
  final String? learningOutcome;
  final int? updatedBy;
  final int? deletedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? domainCategory;
  final String? sourceDataset;
  final String? sourceTitle;
  final List<Answer> answers;
  final List<Mapping> mappings;

  Question({
    required this.id,
    this.questionTypeId,
    this.gradeId,
    this.standardId,
    this.subjectId,
    this.chapterId,
    this.paperCategory,
    this.topicId,
    this.questionTitle,
    this.description,
    this.points,
    this.multipleAnswer,
    this.concept,
    this.subconcept,
    this.preGradeTopic,
    this.postGradeTopic,
    this.crossCurriculumGradeTopic,
    this.subInstituteId,
    this.status,
    this.createdBy,
    this.createdOn,
    this.answer,
    this.hintText,
    this.learningOutcome,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.domainCategory,
    this.sourceDataset,
    this.sourceTitle,
    required this.answers,
    required this.mappings,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      questionTypeId: json['question_type_id'],
      gradeId: json['grade_id'],
      standardId: json['standard_id'],
      subjectId: json['subject_id'],
      chapterId: json['chapter_id'],
      paperCategory: json['paper_category'],
      topicId: json['topic_id'],
      questionTitle: json['question_title'],
      description: json['description'],
      points: json['points'],
      multipleAnswer: json['multiple_answer'],
      concept: json['concept'],
      subconcept: json['subconcept'],
      preGradeTopic: json['pre_grade_topic'],
      postGradeTopic: json['post_grade_topic'],
      crossCurriculumGradeTopic: json['cross_curriculum_grade_topic'],
      subInstituteId: json['sub_institute_id'],
      status: json['status'],
      createdBy: json['created_by'],
      createdOn: json['created_on'],
      answer: json['answer'],
      hintText: json['hint_text'],
      learningOutcome: json['learning_outcome'],
      updatedBy: json['updated_by'],
      deletedBy: json['deleted_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      domainCategory: json['domain_category'],
      sourceDataset: json['source_dataset'],
      sourceTitle: json['source_title'],
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => Answer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mappings: (json['mappings'] as List<dynamic>?)
              ?.map((e) => Mapping.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question_type_id': questionTypeId,
        'grade_id': gradeId,
        'standard_id': standardId,
        'subject_id': subjectId,
        'chapter_id': chapterId,
        'paper_category': paperCategory,
        'topic_id': topicId,
        'question_title': questionTitle,
        'description': description,
        'points': points,
        'multiple_answer': multipleAnswer,
        'concept': concept,
        'subconcept': subconcept,
        'pre_grade_topic': preGradeTopic,
        'post_grade_topic': postGradeTopic,
        'cross_curriculum_grade_topic': crossCurriculumGradeTopic,
        'sub_institute_id': subInstituteId,
        'status': status,
        'created_by': createdBy,
        'created_on': createdOn,
        'answer': answer,
        'hint_text': hintText,
        'learning_outcome': learningOutcome,
        'updated_by': updatedBy,
        'deleted_by': deletedBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'domain_category': domainCategory,
        'source_dataset': sourceDataset,
        'source_title': sourceTitle,
        'answers': answers.map((e) => e.toJson()).toList(),
        'mappings': mappings.map((e) => e.toJson()).toList(),
      };
}

class Answer {
  final int id;
  final int? questionId;
  final String? answer;
  final String? feedback;
  final int? correctAnswer;
  final int? subInstituteId;
  final int? createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  Answer({
    required this.id,
    this.questionId,
    this.answer,
    this.feedback,
    this.correctAnswer,
    this.subInstituteId,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] ?? 0,
      questionId: json['question_id'],
      answer: json['answer'],
      feedback: json['feedback'],
      correctAnswer: json['correct_answer'],
      subInstituteId: json['sub_institute_id'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      deletedBy: json['deleted_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question_id': questionId,
        'answer': answer,
        'feedback': feedback,
        'correct_answer': correctAnswer,
        'sub_institute_id': subInstituteId,
        'created_by': createdBy,
        'updated_by': updatedBy,
        'deleted_by': deletedBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };
}

class Mapping {
  final int id;
  final int? questionmasterId;
  final int? mappingTypeId;
  final int? mappingValueId;
  final String? reasons;
  final int? createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final int? subInstituteId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  Mapping({
    required this.id,
    this.questionmasterId,
    this.mappingTypeId,
    this.mappingValueId,
    this.reasons,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.subInstituteId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Mapping.fromJson(Map<String, dynamic> json) {
    return Mapping(
      id: json['id'] ?? 0,
      questionmasterId: json['questionmaster_id'],
      mappingTypeId: json['mapping_type_id'],
      mappingValueId: json['mapping_value_id'],
      reasons: json['reasons'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      deletedBy: json['deleted_by'],
      subInstituteId: json['sub_institute_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionmaster_id': questionmasterId,
        'mapping_type_id': mappingTypeId,
        'mapping_value_id': mappingValueId,
        'reasons': reasons,
        'created_by': createdBy,
        'updated_by': updatedBy,
        'deleted_by': deletedBy,
        'sub_institute_id': subInstituteId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };
}
