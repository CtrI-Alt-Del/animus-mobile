abstract class NavigationDriver {
  void goTo(String route, {Object? data});
  void goBack();
  bool canGoBack();
}
