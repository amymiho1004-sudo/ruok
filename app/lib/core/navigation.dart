import 'package:flutter/material.dart';

extension NavigationX on BuildContext {
  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));

  void replaceWith(Widget page) =>
      Navigator.of(this).pushReplacement(MaterialPageRoute(builder: (_) => page));

  /// Clears the whole stack, e.g. after logout.
  void resetTo(Widget page) => Navigator.of(this)
      .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => page), (_) => false);

  void pop<T>([T? result]) => Navigator.of(this).pop(result);
}
