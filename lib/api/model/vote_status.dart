enum VoteStatus {
  progress,
  end;

  String get serverValue {
    switch (this) {
      case VoteStatus.progress:
        return 'PROGRESS';
      case VoteStatus.end:
        return 'END';
    }
  }

  static VoteStatus fromServerValue(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    switch (normalized) {
      case 'END':
        return VoteStatus.end;
      case 'PROGRESS':
      default:
        return VoteStatus.progress;
    }
  }
}
