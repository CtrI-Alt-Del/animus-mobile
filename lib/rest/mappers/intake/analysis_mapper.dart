import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_status_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class AnalysisMapper {
  const AnalysisMapper._();

  static AnalysisDto toDto(Json json) {
    final AnalysisTypeDto type = _toType((json['type'] as String?) ?? '');

    return AnalysisDto(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? '',
      accountId: (json['account_id'] as String?) ?? '',
      type: type,
      status: _toStatus(type: type, value: (json['status'] as String?) ?? ''),
      summary: (json['summary'] as String?) ?? '',
      createdAt:
          (json['created_at'] as String?) ??
          (json['createdAt'] as String?) ??
          '',
      folderId: json['folder_id'] as String?,
      isArchived: (json['is_archived'] as bool?) ?? false,
    );
  }

  static AnalysisTypeDto _toType(String value) {
    switch (value) {
      case 'CASE_ASSESSMENT':
        return AnalysisTypeDto.caseAssessment;
      case 'FIRST_INSTANCE':
      case 'LAWYER':
        return AnalysisTypeDto.firstInstance;
      case 'SECOND_INSTANCE':
      case 'JUDGE':
        return AnalysisTypeDto.secondInstance;
      default:
        return AnalysisTypeDto.firstInstance;
    }
  }

  static AnalysisStatusDto _toStatus({
    required AnalysisTypeDto type,
    required String value,
  }) {
    if (type == AnalysisTypeDto.caseAssessment) {
      final CaseAssessmentAnalysisStatusDto status =
          CaseAssessmentAnalysisStatusDto.values.firstWhere(
            (CaseAssessmentAnalysisStatusDto item) => item.value == value,
            orElse: () => CaseAssessmentAnalysisStatusDto.waitingDocumentUpload,
          );

      return AnalysisStatusDto.caseAssessment(status);
    }

    if (type == AnalysisTypeDto.firstInstance) {
      final FirstInstanceAnalysisStatusDto status =
          FirstInstanceAnalysisStatusDto.values.firstWhere(
            (FirstInstanceAnalysisStatusDto item) => item.value == value,
            orElse: () => FirstInstanceAnalysisStatusDto.waitingDocumentUpload,
          );

      return AnalysisStatusDto.firstInstance(status);
    }

    final SecondInstanceAnalysisStatusDto status =
        SecondInstanceAnalysisStatusDto.values.firstWhere(
          (SecondInstanceAnalysisStatusDto item) => item.value == value,
          orElse: () => SecondInstanceAnalysisStatusDto.waitingDocumentUpload,
        );

    return AnalysisStatusDto.secondInstance(status);
  }
}
