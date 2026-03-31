import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class IntakeService {
  Future<RestResponse<PetitionDto>> createPetition({
    required PetitionDto petition,
  });

  Future<RestResponse<PetitionSummaryDto>> summarizePetition({
    required String petitionId,
  });
}
