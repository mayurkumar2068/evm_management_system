import 'package:flutter/material.dart';

/// The base scaffold used by every screen, centralizing app-bar styling,
/// safe-area handling and optional drawer/bottom-nav wiring.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.actions,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.leading,
    this.resizeToAvoidBottomInset = true,
    this.padded = true,
    super.key,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? leading;
  final bool resizeToAvoidBottomInset;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions, leading: leading),
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: padded
            ? Padding(padding: const EdgeInsets.all(16), child: body)
            : body,
      ),
    );
  }
}
