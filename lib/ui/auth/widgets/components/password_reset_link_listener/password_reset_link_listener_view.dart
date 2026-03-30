import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/ui/auth/widgets/components/password_reset_link_listener/password_reset_link_listener_presenter.dart';

class PasswordResetLinkListenerView extends ConsumerStatefulWidget {
  final Widget child;

  const PasswordResetLinkListenerView({required this.child, super.key});

  @override
  ConsumerState<PasswordResetLinkListenerView> createState() =>
      _PasswordResetLinkListenerViewState();
}

class _PasswordResetLinkListenerViewState
    extends ConsumerState<PasswordResetLinkListenerView> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(passwordResetLinkListenerPresenterProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
