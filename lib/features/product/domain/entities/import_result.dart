import 'package:equatable/equatable.dart';

class ImportResult extends Equatable {
  final int imported;
  final int skippedDuplicate;
  final int skippedInvalid;
  final List<String> errors;

  const ImportResult({
    this.imported = 0,
    this.skippedDuplicate = 0,
    this.skippedInvalid = 0,
    this.errors = const [],
  });

  @override
  List<Object?> get props => [imported, skippedDuplicate, skippedInvalid, errors];
}
