import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/rest/mappers/storage/upload_url_mapper.dart';
import 'package:animus/rest/services/service.dart';

class StorageRestService extends Service implements StorageService {
  StorageRestService({
    required RestClient restClient,
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
  }) : super(restClient, cacheDriver, navigationDriver);

  @override
  Future<RestResponse<UploadUrlDto>> generatePetitionUploadUrl({
    required String analysisId,
    required String documentType,
  }) async {
    final RestResponse<UploadUrlDto>? authFailure = requireAuth<UploadUrlDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/storage/analyses/$analysisId/petitions/upload',
      queryParams: <String, dynamic>{'document_type': documentType},
    );

    return response.mapBody<UploadUrlDto>(UploadUrlMapper.toDto);
  }
}
