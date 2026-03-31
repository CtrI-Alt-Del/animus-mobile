import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/rest/mappers/storage/upload_url_mapper.dart';

class StorageRestService implements StorageService {
  final RestClient _restClient;

  const StorageRestService({required RestClient restClient})
    : _restClient = restClient;

  @override
  Future<RestResponse<UploadUrlDto>> getPetitionUploadUrl({
    required String analysisId,
    required String documentType,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await _restClient.post(
      '/storage/analyses/$analysisId/petitions/upload',
      queryParams: <String, dynamic>{'document_type': documentType},
    );

    return response.mapBody<UploadUrlDto>(UploadUrlMapper.toDto);
  }
}
