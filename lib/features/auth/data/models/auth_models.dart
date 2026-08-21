import 'user_model.dart';

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
    };
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return LoginResponse(
      accessToken: json["accessToken"],
      refreshToken: json["refreshToken"],
      user: UserModel.fromJson(
        json["user"],
      ),
    );
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String role;
  final String? designation;
  final String? phone;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.designation,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
      "firstName": firstName,
      "lastName": lastName,
      "role": role,
      "designation": designation,
      "phone": phone,
    };
  }
}

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
    };
  }
}

class ResetPasswordRequest {
  final String token;
  final String password;

  ResetPasswordRequest({
    required this.token,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "token": token,
      "password": password,
    };
  }
}

class VerifyEmailRequest {
  final String userId;
  final String code;

  VerifyEmailRequest({
    required this.userId,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "code": code,
    };
  }
}