class InputValidator {
  const InputValidator();

  String? voteName(String value) {
    return value.trim().isEmpty ? 'Vote name is required.' : null;
  }

  String? questionImageUrl(String value) {
    return value.trim().isEmpty ? 'Question image URL is required.' : null;
  }

  String? positiveImageRatio(double value) {
    return value > 0 ? null : 'Question image ratio must be greater than zero.';
  }

  String? nonEmptyUrlConfig(String value, String label) {
    return value.trim().isEmpty ? '$label is required.' : null;
  }
}
