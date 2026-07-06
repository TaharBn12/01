import 'package:get_it/get_it.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/product_usecases.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/shop/data/repositories/shop_repository_impl.dart';
import '../../features/shop/domain/repositories/shop_repository.dart';
import '../../features/shop/domain/usecases/shop_usecases.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';
import '../../features/settings/data/repositories/printer_repository_impl.dart';
import '../../features/settings/domain/repositories/printer_repository.dart';
import '../../features/settings/presentation/bloc/printer_bloc.dart';
import '../../features/billing/data/repositories/invoice_repository_impl.dart';
import '../../features/billing/domain/repositories/invoice_repository.dart';
import '../../features/expense/data/repositories/expense_repository_impl.dart';
import '../../features/expense/domain/repositories/expense_repository.dart';
import '../../features/expense/domain/usecases/expense_usecases.dart';
import '../../features/expense/presentation/bloc/expense_bloc.dart';
import '../../features/ai_order/domain/services/order_parser.dart';
import '../../features/ai_order/data/services/order_parser_impl.dart';
import '../../features/ai_order/presentation/bloc/ai_order_bloc.dart';
import '../../features/ai_assistant/domain/services/business_assistant.dart';
import '../../features/ai_assistant/data/services/business_assistant_impl.dart';
import '../../features/ai_assistant/presentation/bloc/assistant_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Product
  // Bloc
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
      exportProductsUseCase: sl(),
      importProductsUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ShopBloc(
      getShopUseCase: sl(),
      updateShopUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => PrinterBloc(
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));
  sl.registerLazySingleton(() => ExportProductsUseCase(sl()));
  sl.registerLazySingleton(() => ImportProductsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(),
  );

  // Features - Shop
  // Use cases
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(),
  );

  // Features - Settings / Printer
  sl.registerLazySingleton<PrinterRepository>(
    () => PrinterRepositoryImpl(),
  );

  // Features - Billing
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(),
  );

  // Features - Expense
  sl.registerFactory(
    () => ExpenseBloc(
      addExpenseUseCase: sl(),
      getExpensesByDateRangeUseCase: sl(),
      deleteExpenseUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => AddExpenseUseCase(sl()));
  sl.registerLazySingleton(() => GetExpensesByDateRangeUseCase(sl()));
  sl.registerLazySingleton(() => GetAllExpensesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(),
  );

  // Features - AI Order
  sl.registerLazySingleton<OrderParser>(
    () => OrderParserImpl([]),
  );
  sl.registerFactory(
    () => AiOrderBloc(parser: sl()),
  );

  // Features - AI Assistant
  sl.registerLazySingleton<BusinessAssistant>(
    () => BusinessAssistantImpl(),
  );
  sl.registerFactory(
    () => AssistantBloc(assistant: sl()),
  );
}
