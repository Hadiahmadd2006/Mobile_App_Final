import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// An [AppBar] that toggles into an in-page search field.
///
/// The parent screen owns the query (delivered via [onChanged]) and filters
/// its own content — this widget only manages the show/hide of the field.
class InPageSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String hint;
  final bool large;
  final ValueChanged<String> onChanged;

  /// Extra actions shown (before the search icon) when not searching.
  final List<Widget> actions;

  const InPageSearchAppBar({
    super.key,
    required this.title,
    required this.onChanged,
    this.hint = 'Search this page…',
    this.large = false,
    this.actions = const [],
  });

  double get _height => large ? 74 : kToolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(_height);

  @override
  State<InPageSearchAppBar> createState() => _InPageSearchAppBarState();
}

class _InPageSearchAppBarState extends State<InPageSearchAppBar> {
  final TextEditingController _controller = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() => setState(() => _searching = true);

  void _close() {
    _controller.clear();
    widget.onChanged('');
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: widget._height,
      title: _searching
          ? TextField(
              controller: _controller,
              autofocus: true,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.body.copyWith(fontSize: 18),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.bodyMuted.copyWith(fontSize: 18),
                filled: false,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            )
          : Text(
              widget.title,
              style: widget.large
                  ? AppTextStyles.heading.copyWith(fontSize: 30)
                  : null,
            ),
      actions: _searching
          ? [
              IconButton(
                tooltip: 'Close search',
                icon: const Icon(Icons.close_rounded),
                onPressed: _close,
              ),
            ]
          : [
              ...widget.actions,
              IconButton(
                tooltip: 'Search this page',
                icon: const Icon(Icons.search_rounded),
                onPressed: _open,
              ),
            ],
    );
  }
}
