import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/product/domain/entities/import_result.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';

class MockProductRepository implements ProductRepository {
  List<Product>? productsToReturn;
  ImportResult? importResultToReturn;
  Failure? importFailureToReturn;
  String? importedCsvContent;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    return Right(productsToReturn ?? []);
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> exportProductsToCsv(
      List<Product> products) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ImportResult>> importProductsFromCsv(
      String csvContent) async {
    importedCsvContent = csvContent;
    if (importFailureToReturn != null) {
      return Left(importFailureToReturn!);
    }
    return Right(importResultToReturn ??
        const ImportResult(imported: 0, skippedDuplicate: 0, skippedInvalid: 0));
  }
}

void main() {
  late MockProductRepository mockRepository;
  late ImportProductsUseCase useCase;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = ImportProductsUseCase(mockRepository);
  });

  const tCsvContent = 'name,barcode,price,stock,costPrice\n'
      'Product A,123456,100.0,10,70.0\n'
      'Product B,789012,200.0,5,150.0';

  group('ImportProductsUseCase', () {
    test('should return Right(ImportResult) when import succeeds', () async {
      // arrange
      mockRepository.importResultToReturn = const ImportResult(
        imported: 2,
        skippedDuplicate: 0,
        skippedInvalid: 0,
      );

      // act
      final result = await useCase(tCsvContent);

      // assert
      expect(
        result,
        equals(
          const Right<Failure, ImportResult>(
            ImportResult(
              imported: 2,
              skippedDuplicate: 0,
              skippedInvalid: 0,
            ),
          ),
        ),
      );
      expect(mockRepository.importedCsvContent, equals(tCsvContent));
    });

    test('should return Right(ImportResult) when duplicates are skipped',
        () async {
      // arrange
      mockRepository.importResultToReturn = const ImportResult(
        imported: 1,
        skippedDuplicate: 1,
        skippedInvalid: 0,
      );

      // act
      final result = await useCase(tCsvContent);

      // assert
      expect(
        result,
        equals(
          const Right<Failure, ImportResult>(
            ImportResult(
              imported: 1,
              skippedDuplicate: 1,
              skippedInvalid: 0,
            ),
          ),
        ),
      );
      expect(mockRepository.importedCsvContent, equals(tCsvContent));
    });

    test('should return Right(ImportResult) when invalid rows are skipped',
        () async {
      // arrange
      mockRepository.importResultToReturn = const ImportResult(
        imported: 1,
        skippedDuplicate: 0,
        skippedInvalid: 1,
      );

      // act
      final result = await useCase(tCsvContent);

      // assert
      expect(
        result,
        equals(
          const Right<Failure, ImportResult>(
            ImportResult(
              imported: 1,
              skippedDuplicate: 0,
              skippedInvalid: 1,
            ),
          ),
        ),
      );
      expect(mockRepository.importedCsvContent, equals(tCsvContent));
    });

    test('should return Left(Failure) when repository returns a failure',
        () async {
      // arrange
      mockRepository.importFailureToReturn = const CacheFailure('Parse error');

      // act
      final result = await useCase(tCsvContent);

      // assert
      expect(
        result,
        equals(
          const Left<Failure, ImportResult>(CacheFailure('Parse error')),
        ),
      );
      expect(mockRepository.importedCsvContent, equals(tCsvContent));
    });
  });
}
