import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class IntakeService {
  Future<RestResponse<PetitionDto>> createPetition({
    required PetitionDto petition,
  });

  Future<RestResponse<AnalysisDto>> getAnalysis({required String analysisId});

  Future<RestResponse<PetitionDto>> getAnalysisPetition({
    required String analysisId,
  });

  Future<RestResponse<PetitionSummaryDto>> getPetitionSummary({
    required String petitionId,
  });

  Future<RestResponse<PetitionSummaryDto>> summarizePetition({
    required String petitionId,
  });
}
