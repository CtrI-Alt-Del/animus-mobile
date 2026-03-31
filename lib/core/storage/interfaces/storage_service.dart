import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class StorageService {
  Future<RestResponse<UploadUrlDto>> getPetitionUploadUrl({
    required String analysisId,
    required String documentType,
  });
}
