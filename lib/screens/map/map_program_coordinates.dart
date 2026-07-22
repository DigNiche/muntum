import 'package:muntum/models/program_model.dart';

extension ProgramMapCoordinates on ProgramModel {
  double? get latitude => double.tryParse(location['latitude'] ?? '');

  double? get longitude => double.tryParse(location['longitude'] ?? '');

  bool get hasMapCoordinates => latitude != null && longitude != null;
}
