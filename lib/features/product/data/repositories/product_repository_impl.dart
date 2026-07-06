import 'package:csv/csv.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final box = HiveDatabase.productBox;
      final products = box.values.toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final box = HiveDatabase.productBox;
      final product = box.values.firstWhere(
        (element) => element.barcode == barcode,
        orElse: () => throw Exception('Product not found'),
      );
      return Right(product);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      // You can use add() or put()
      final model = ProductModel.fromEntity(product);
      await box.put(model.id, model); // Using ID as key
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      final model = ProductModel.fromEntity(product);
      await box.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      final box = HiveDatabase.productBox;
      await box.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> exportProductsToCsv(
      List<Product> products) async {
    try {
      final rows = [
        ['name', 'barcode', 'price', 'stock', 'costPrice'],
        ...products.map((product) => [
              product.name,
              product.barcode,
              product.price,
              product.stock,
              product.costPrice,
            ]),
      ];
      final csvString = const ListToCsvConverter().convert(rows);
      return Right(csvString);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ImportResult>> importProductsFromCsv(
      String csvContent) async {
    try {
      final rows = const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) {
        return const Right(ImportResult());
      }

      final header = rows.first.map((cell) => cell.toString().trim().toLowerCase()).toList();
      const expectedHeader = ['name', 'barcode', 'price', 'stock', 'costprice'];
      if (header.length != expectedHeader.length ||
          !header.asMap().entries.every(
                (entry) => entry.value == expectedHeader[entry.key],
              )) {
        return Left(CacheFailure('Invalid CSV header'));
      }

      final existingProductsResult = await getProducts();
      final existingBarcodes = existingProductsResult.fold(
        (failure) => <String>{},
        (products) => products.map((p) => p.barcode).toSet(),
      );

      int imported = 0;
      int skippedDuplicate = 0;
      int skippedInvalid = 0;
      final errors = <String>[];

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];

        if (row.length < 5) {
          skippedInvalid++;
          errors.add('Row ${i + 1}: insufficient columns');
          continue;
        }

        final name = row[0].toString().trim();
        final barcode = row[1].toString().trim();

        if (name.isEmpty || barcode.isEmpty) {
          skippedInvalid++;
          errors.add('Row ${i + 1}: empty name or barcode');
          continue;
        }

        if (existingBarcodes.contains(barcode)) {
          skippedDuplicate++;
          errors.add('Row ${i + 1}: duplicate barcode $barcode');
          continue;
        }

        final double price;
        final int stock;
        final double costPrice;

        try {
          price = double.parse(row[2].toString().trim());
          stock = int.parse(row[3].toString().trim());
          costPrice = double.parse(row[4].toString().trim());
        } catch (e) {
          skippedInvalid++;
          errors.add('Row ${i + 1}: invalid numeric value');
          continue;
        }

        final product = Product(
          id: const Uuid().v4(),
          name: name,
          barcode: barcode,
          price: price,
          stock: stock,
          costPrice: costPrice,
        );

        final addResult = await addProduct(product);
        addResult.fold(
          (failure) {
            skippedInvalid++;
            errors.add('Row ${i + 1}: ${failure.toString()}');
          },
          (_) {
            imported++;
            existingBarcodes.add(barcode);
          },
        );
      }

      return Right(ImportResult(
        imported: imported,
        skippedDuplicate: skippedDuplicate,
        skippedInvalid: skippedInvalid,
        errors: errors,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
