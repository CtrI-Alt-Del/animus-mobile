import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/mappers/intake/petition_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_summary_mapper.dart';

class IntakeRestService implements IntakeService {
  final RestClient _restClient;

  const IntakeRestService({required RestClient restClient})
    : _restClient = restClient;

  @override
  Future<RestResponse<PetitionDto>> createPetition({
    required PetitionDto petition,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await _restClient.post(
      '/petitions',
      body: PetitionMapper.toJson(petition),
    );

    return response.mapBody<PetitionDto>(PetitionMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionSummaryDto>> summarizePetition({
    required String petitionId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await _restClient.post(
      '/petitions/$petitionId/summary',
    );

    return response.mapBody<PetitionSummaryDto>(PetitionSummaryMapper.toDto);
  }
}
