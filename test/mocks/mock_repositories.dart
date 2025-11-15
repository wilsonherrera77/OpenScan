import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:openscan_indigenas/data/repositories/auth_repository.dart';
import 'package:openscan_indigenas/data/repositories/census_repository.dart';
import 'package:openscan_indigenas/data/repositories/document_repository.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([
  AuthRepository,
  CensusRepository,
  DocumentRepository,
])
void main() {}
