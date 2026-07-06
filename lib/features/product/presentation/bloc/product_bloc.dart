import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/product_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase getProductsUseCase;
  final AddProductUseCase addProductUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final DeleteProductUseCase deleteProductUseCase;
  final ExportProductsUseCase exportProductsUseCase;
  final ImportProductsUseCase importProductsUseCase;

  ProductBloc({
    required this.getProductsUseCase,
    required this.addProductUseCase,
    required this.updateProductUseCase,
    required this.deleteProductUseCase,
    required this.exportProductsUseCase,
    required this.importProductsUseCase,
  }) : super(const ProductState()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<ExportProducts>(_onExportProducts);
    on<ImportProducts>(_onImportProducts);
  }

  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading));
    final result = await getProductsUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
          status: ProductStatus.error, message: failure.message)),
      (products) => emit(
          state.copyWith(status: ProductStatus.loaded, products: products)),
    );
  }

  Future<void> _onAddProduct(
      AddProduct event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading)); // Keep products
    final result = await addProductUseCase(event.product);
    result.fold(
      (failure) => emit(state.copyWith(
          status: ProductStatus.error, message: failure.message)),
      (_) {
        emit(state.copyWith(
            status: ProductStatus.success,
            message: 'Product added successfully'));
        add(LoadProducts());
      },
    );
  }

  Future<void> _onUpdateProduct(
      UpdateProduct event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading));
    final result = await updateProductUseCase(event.product);
    result.fold(
      (failure) => emit(state.copyWith(
          status: ProductStatus.error, message: failure.message)),
      (_) {
        emit(state.copyWith(
            status: ProductStatus.success,
            message: 'Product updated successfully'));
        add(LoadProducts());
      },
    );
  }

  Future<void> _onDeleteProduct(
      DeleteProduct event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading));
    final result = await deleteProductUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
          status: ProductStatus.error, message: failure.message)),
      (_) {
        emit(state.copyWith(
            status: ProductStatus.success,
            message: 'Product deleted successfully'));
        add(LoadProducts());
      },
    );
  }

  Future<void> _onExportProducts(
      ExportProducts event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading));
    final result = await exportProductsUseCase(NoParams());
    await result.fold(
      (failure) async => emit(state.copyWith(
          status: ProductStatus.error, message: failure.message)),
      (csvString) async {
        try {
          final tempDir = await getTemporaryDirectory();
          final fileName =
              'products_export_${DateTime.now().millisecondsSinceEpoch}.csv';
          final filePath = '${tempDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsString(csvString);

          try {
            await Share.shareXFiles([XFile(filePath)],
                subject: 'Exported Products');
          } catch (_) {
            // Fallback: just notify the caller with the saved path.
          }

          emit(state.copyWith(
              status: ProductStatus.success,
              message: 'Exported products to $filePath'));
        } catch (e) {
          emit(state.copyWith(
              status: ProductStatus.error,
              message: 'Failed to save export: ${e.toString()}'));
        }
      },
    );
  }

  Future<void> _onImportProducts(
      ImportProducts event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading));
    final result = await importProductsUseCase(event.csvContent);
    result.fold(
      (failure) => emit(state.copyWith(
          status: ProductStatus.error, message: failure.message)),
      (ImportResult importResult) {
        emit(state.copyWith(
            status: ProductStatus.success,
            message:
                'Imported ${importResult.imported}, skipped duplicate ${importResult.skippedDuplicate}, skipped invalid ${importResult.skippedInvalid}'));
        add(LoadProducts());
      },
    );
  }
}
