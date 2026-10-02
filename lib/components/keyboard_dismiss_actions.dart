import 'package:flutter/material.dart';

/// Makes touch taps outside any editable field dismiss its keyboard as well.
class KeyboardDismissActions extends StatelessWidget {
  const KeyboardDismissActions({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: <Type, Action<Intent>>{
      EditableTextTapOutsideIntent:
          CallbackAction<EditableTextTapOutsideIntent>(
            onInvoke: (intent) {
              intent.focusNode.unfocus();
              return null;
            },
          ),
    },
    child: child,
  );
}
