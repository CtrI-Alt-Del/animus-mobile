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
  });
}
