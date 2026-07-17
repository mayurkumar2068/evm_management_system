import 'dart:async';

import 'package:evm_management_system/shared/design_system/tokens/app_icons.dart';
import 'package:flutter/material.dart';

/// Debounced search input used by list/search screens.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.hint,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 350),
    this.controller,
    super.key,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounce;
  final TextEditingController? controller;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(AppIcons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (BuildContext context, TextEditingValue value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            );
          },
        ),
      ),
    );
  }
}
