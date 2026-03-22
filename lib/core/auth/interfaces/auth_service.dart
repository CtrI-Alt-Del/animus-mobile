import 'package:animus_mobile/core/auth/dtos/account_dto.dart';
import 'package:animus_mobile/core/shared/responses/rest_response.dart';

abstract class AuthService {
  Future<RestResponse<AccountDto>> isLoggedInWithCredentialsAndToken({
    String accountame,
    String password,
  });
}
