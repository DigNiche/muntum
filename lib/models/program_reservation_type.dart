enum ProgramReservationType {
  preRegistration('PRE_REGISTRATION', '사전예약'),
  onSite('ON_SITE', '현장예매'),
  preRegistrationAndOnSite('PRE_REGISTRATION_AND_ON_SITE', '사전예약·현장예매'),
  freeEntry('FREE_ENTRY', '자유관람');

  const ProgramReservationType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get needsReservation => this != freeEntry;

  bool get allowsReservationUrl =>
      this == preRegistration || this == preRegistrationAndOnSite;

  static ProgramReservationType? fromApiValue(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}
