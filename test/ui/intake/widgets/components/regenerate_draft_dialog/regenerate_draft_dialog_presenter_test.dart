import 'dart:async';

import 'package:animus/ui/intake/widgets/components/regenerate_draft_dialog/regenerate_draft_dialog_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegenerateDraftDialogPresenter', () {
    test(
      'should disable confirm and show validation error for blank comments',
      () async {
        final RegenerateDraftDialogPresenter presenter =
            RegenerateDraftDialogPresenter();
        addTearDown(presenter.dispose);

        presenter.updateComments('   ');

        expect(presenter.canConfirm.value, isFalse);
        expect(await presenter.confirm((String _) async {}), isFalse);
        expect(
          presenter.validationError.value,
          'Descreva as alterações desejadas para regerar a minuta.',
        );
      },
    );

    test(
      'should trim comments and confirm immediately for valid input',
      () async {
        final RegenerateDraftDialogPresenter presenter =
            RegenerateDraftDialogPresenter();
        addTearDown(presenter.dispose);
        String? receivedComments;

        presenter.updateComments('  Ajustar fundamentos e pedidos.  ');

        final bool didConfirm = await presenter.confirm((
          String comments,
        ) async {
          receivedComments = comments;
        });

        expect(didConfirm, isTrue);
        expect(receivedComments, 'Ajustar fundamentos e pedidos.');
        expect(presenter.validationError.value, isNull);
        expect(presenter.isSubmitting.value, isTrue);
      },
    );

    test(
      'should ignore duplicate confirm while submission is in progress',
      () async {
        final RegenerateDraftDialogPresenter presenter =
            RegenerateDraftDialogPresenter();
        addTearDown(presenter.dispose);
        final Completer<void> completer = Completer<void>();
        int confirmCalls = 0;

        presenter.updateComments('Ajustar fundamentos.');

        final bool firstDidConfirm = await presenter.confirm((String _) {
          confirmCalls++;
          return completer.future;
        });
        final bool secondDidConfirm = await presenter.confirm((String _) async {
          confirmCalls++;
        });

        expect(firstDidConfirm, isTrue);
        expect(secondDidConfirm, isFalse);
        expect(confirmCalls, 1);

        completer.complete();
      },
    );

    test('should reset submission state when onConfirm throws', () async {
      final RegenerateDraftDialogPresenter presenter =
          RegenerateDraftDialogPresenter();
      addTearDown(presenter.dispose);

      presenter.updateComments('Ajustar fundamentos.');

      expect(
        await presenter.confirm((String _) async {
          throw Exception('Falha ao confirmar');
        }),
        isTrue,
      );

      await Future<void>.delayed(Duration.zero);

      expect(presenter.isSubmitting.value, isFalse);
    });
  });
}
