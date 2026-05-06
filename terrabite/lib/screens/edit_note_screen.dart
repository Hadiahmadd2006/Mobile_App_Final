import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/favorite_meal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/network_image_box.dart';

class EditNoteScreen extends StatefulWidget {
  final String mealId;

  const EditNoteScreen({super.key, required this.mealId});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  Future<FavoriteMeal?>? _loadFuture;
  FavoriteMeal? _original;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<FavoriteMeal?> _load() async {
    final repo = AppScope.of(context).favorites;
    final meal = await repo.getById(widget.mealId);
    if (meal != null) {
      _titleController.text = meal.noteTitle;
      _bodyController.text = meal.noteBody;
      _original = meal;
    }
    return meal;
  }

  String? _validateTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Title is required.';
    if (trimmed.length > 60) return 'Keep the title under 60 characters.';
    return null;
  }

  String? _validateBody(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Note body is required.';
    if (trimmed.length < 10) return 'Add at least 10 characters.';
    return null;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    final repo = AppScope.of(context).favorites;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() => _saving = true);
    try {
      await repo.updateNote(
        id: widget.mealId,
        noteTitle: _titleController.text.trim(),
        noteBody: _bodyController.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Note saved.')));
      if (router.canPop()) {
        router.pop();
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
      setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final hasChanges =
        _original != null &&
        (_titleController.text.trim() != _original!.noteTitle ||
            _bodyController.text.trim() != _original!.noteBody);
    if (!hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this note will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        final allow = await _confirmDiscard();
        if (!mounted) return;
        if (allow) router.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit note'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_saving ? 'Saving…' : 'Save note'),
        ),
        body: SafeArea(
          child: FutureBuilder<FavoriteMeal?>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }
              if (snapshot.hasError) {
                return ErrorView(message: snapshot.error.toString());
              }
              final meal = snapshot.data;
              if (meal == null) {
                return const ErrorView(
                  message: 'This recipe is no longer in your favorites.',
                  icon: Icons.bookmark_remove_outlined,
                );
              }
              return _NoteForm(
                meal: meal,
                formKey: _formKey,
                titleController: _titleController,
                bodyController: _bodyController,
                validateTitle: _validateTitle,
                validateBody: _validateBody,
                onSubmit: _save,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NoteForm extends StatelessWidget {
  final FavoriteMeal meal;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final FormFieldValidator<String> validateTitle;
  final FormFieldValidator<String> validateBody;
  final Future<void> Function() onSubmit;

  const _NoteForm({
    required this.meal,
    required this.formKey,
    required this.titleController,
    required this.bodyController,
    required this.validateTitle,
    required this.validateBody,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceLg,
        AppTheme.spaceLg,
        AppTheme.spaceLg,
        96,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: AppTheme.cardDecoration,
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: NetworkImageBox(
                      url: meal.thumbnailUrl,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${meal.area} · ${meal.category}',
                          style: AppTextStyles.label,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              'NOTE TITLE',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.highlight,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            TextFormField(
              controller: titleController,
              validator: validateTitle,
              maxLength: 60,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              decoration: const InputDecoration(
                hintText: 'e.g. "Tweaks for next time"',
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              'NOTES',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.highlight,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            TextFormField(
              controller: bodyController,
              validator: validateBody,
              maxLines: 8,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                hintText:
                    'Cooking observations, swaps, ratings… (min 10 characters)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (GoRouter.of(context).canPop()) {
                        GoRouter.of(context).pop();
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onSubmit(),
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
