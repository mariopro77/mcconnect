// models/division.dart

class Division {
  final int idDivision;
  final String division;

  Division({
    required this.idDivision,
    required this.division,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      idDivision: json['id_division'],
      division: json['division'] ?? '',
    );
  }
}
