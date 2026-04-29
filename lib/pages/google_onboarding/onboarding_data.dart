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

class RegistroClienteModel {
  ClientType? clientType;
  String? name;
  String? taxId;
  String? phone;
  String? address;
  String? city;
  // Default a República Dominicana: la mayoría de clientes son dominicanos
  // y el campo TaxId del paso 1 necesita conocer el país antes de que el
  // usuario lo seleccione en el paso 2.
  String country = 'República Dominicana';

  bool get isCompany =>
      clientType == ClientType.empresa ||
      clientType == ClientType.zonaFranca ||
      clientType == ClientType.gubernamental;

  bool get isDominicanRepublic =>
      country.trim().toLowerCase() == 'república dominicana' ||
      country.trim().toLowerCase() == 'republica dominicana';
}

typedef OnboardingData = RegistroClienteModel;
