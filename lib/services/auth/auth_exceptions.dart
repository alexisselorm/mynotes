// Login exceptions
class UserNotVerifiedAuthException implements Exception {
  final String message;

  UserNotVerifiedAuthException([this.message = 'User email is not verified.']);

  @override
  String toString() => 'UserNotVerifiedAuthException: $message';
}

class UserNotFoundAuthException implements Exception {
  final String message;

  UserNotFoundAuthException([this.message = 'User not found.']);

  @override
  String toString() => 'UserNotFoundAuthException: $message';
}

class WrongPasswordAuthException implements Exception {
  final String message;

  WrongPasswordAuthException([this.message = 'Wrong password provided.']);

  @override
  String toString() => 'WrongPasswordAuthException: $message';
}

// REGISTER exceptions
class WeakPasswordAuthException implements Exception {
  final String message;
  WeakPasswordAuthException([
    this.message = 'The password provided is too weak.',
  ]);

  @override
  String toString() => 'WeakPasswordAuthException: $message';
}

class EmailAlreadyInUseAuthException implements Exception {
  final String message;
  EmailAlreadyInUseAuthException([
    this.message = 'The account already exists for that email.',
  ]);

  @override
  String toString() => 'EmailAlreadyInUseAuthException: $message';
}

class InvalidEmailAuthException implements Exception {
  final String message;
  InvalidEmailAuthException([this.message = 'The email address is not valid.']);

  @override
  String toString() => 'InvalidEmailAuthException: $message';
}

//Generic exceptions

class GenericAuthException implements Exception {
  final String message;
  GenericAuthException([this.message = 'An unknown error occurred.']);

  @override
  String toString() => 'GenericAuthException: $message';
}

class UserNotLoggedInAuthException implements Exception {
  final String message;
  UserNotLoggedInAuthException([this.message = 'User is not logged in.']);

  @override
  String toString() => 'UserNotLoggedInAuthException: $message';
}
