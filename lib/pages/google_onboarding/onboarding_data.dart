enum ClientType { empresa, zonaFranca, gubernamental, personaFisica }

extension ClientTypeX on ClientType {
  String get label {
    switch (this) {
      case ClientType.empresa:
        return 'Empresa';
      case ClientType.zonaFranca:
        return 'Zona Franca';
      case ClientType.gubernamental:
        return 'Gubernamental';
      case ClientType.personaFisica:
        return 'Persona Física';
    }
  }
}

class OnboardingData {
  ClientType? clientType;
  String? name;
  String? taxId;
  String? phone;
  String? address;
  String? city;
  String? country;

  bool get isCompany =>
      clientType == ClientType.empresa ||
      clientType == ClientType.zonaFranca ||
      clientType == ClientType.gubernamental;
}
