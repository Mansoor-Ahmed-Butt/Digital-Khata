/// A phone-book entry offered for import (FR-02).
class ContactCandidate {
  const ContactCandidate({required this.name, this.phone});

  final String name;

  /// Valid Pakistani mobile in 03XXXXXXXXX / +923XXXXXXXXX form, or null.
  final String? phone;
}
