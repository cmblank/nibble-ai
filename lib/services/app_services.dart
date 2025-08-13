import 'package:flutter/widgets.dart';
import 'shopping_list_service.dart';

/// Simple DI scope for sharing service singletons across the app.
class AppServicesScope extends InheritedWidget {
  final ShoppingListService shoppingListService;

  const AppServicesScope({
    super.key,
    required this.shoppingListService,
    required super.child,
  });

  static AppServicesScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppServicesScope>();

  @override
  bool updateShouldNotify(covariant AppServicesScope oldWidget) =>
      shoppingListService != oldWidget.shoppingListService;
}
