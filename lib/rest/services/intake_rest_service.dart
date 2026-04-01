import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/mappers/intake/petition_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_summary_mapper.dart';
import 'package:animus/rest/services/service.dart';

class IntakeRestService extends Service implements IntakeService {
  IntakeRestService({
    required RestClient restClient,
    required CacheDriver cacheDriver,
  }) : super(restClient, cacheDriver);

  @override
  Future<RestResponse<PetitionDto>> createPetition({
    required PetitionDto petition,
  }) async {
    await setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/petitions',
      body: PetitionMapper.toJson(petition),
    );

    return response.mapBody<PetitionDto>(PetitionMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionSummaryDto>> summarizePetition({
    required String petitionId,
  }) async {
    await setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/petitions/$petitionId/summary',
    );

    return response.mapBody<PetitionSummaryDto>(PetitionSummaryMapper.toDto);
  }
}
