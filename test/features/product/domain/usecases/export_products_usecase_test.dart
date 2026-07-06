import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/core/usecase/usecase.dart';
import 'package:billing_app/features/product/domain/entities/import_result.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';

class MockProductRepository implements ProductRepository {
  List<Product>? productsToReturn;
  String? csvToReturn;
  Failure? exportFailureToReturn;
  Failure? getProductsFailureToReturn;
  List<Product>? exportedProducts;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    if (getProductsFailureToReturn != null) {
      return Left(getProductsFailureToReturn!);
    }
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
    exportedProducts = products;
    if (exportFailureToReturn != null) {
      return Left(exportFailureToReturn!);
    }
    return Right(csvToReturn ?? '');
  }

  @override
  Future<Either<Failure, ImportResult>> importProductsFromCsv(
      String csvContent) async {
    throw UnimplementedError();
  }
}

void main() {
  late MockProductRepository mockRepository;
  late ExportProductsUseCase useCase;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = ExportProductsUseCase(mockRepository);
  });

  final tProducts = [
    const Product(
      id: '1',
      name: 'Product A',
      barcode: '123456',
      price: 100.0,
      costPrice: 70.0,
      stock: 10,
    ),
    const Product(
      id: '2',
      name: 'Product B',
      barcode: '789012',
      price: 200.0,
      costPrice: 150.0,
      stock: 5,
    ),
  ];

  const tExpectedCsv =
      'name,barcode,price,stock,costPrice\nProduct A,123456,100.0,10,70.0\nProduct B,789012,200.0,5,150.0';

  group('ExportProductsUseCase', () {
    test(
        'should return Right(csvString) when getProducts and export both succeed',
        () async {
      // arrange
      mockRepository.productsToReturn = tProducts;
      mockRepository.csvToReturn = tExpectedCsv;

      // act
      final result = await useCase(NoParams());

      // assert
      expect(result, equals(const Right<Failure, String>(tExpectedCsv)));
      expect(mockRepository.exportedProducts, equals(tProducts));
    });

    test('should return Left(Failure) when getProducts fails', () async {
      // arrange
      mockRepository.getProductsFailureToReturn =
          const CacheFailure('Failed to load products');

      // act
      final result = await useCase(NoParams());

      // assert
      expect(
        result,
        equals(
          const Left<Failure, String>(
              CacheFailure('Failed to load products')),
        ),
      );
      expect(mockRepository.exportedProducts, isNull);
    });

    test('should return Left(Failure) when export fails', () async {
      // arrange
      mockRepository.productsToReturn = tProducts;
      mockRepository.exportFailureToReturn = const CacheFailure('Export failed');

      // act
      final result = await useCase(NoParams());

      // assert
      expect(
        result,
        equals(const Left<Failure, String>(CacheFailure('Export failed'))),
      );
      expect(mockRepository.exportedProducts, equals(tProducts));
    });
  });
}
