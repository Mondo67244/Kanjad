import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';

/// Enum for different dialog types
enum DialogType { confirmation, loading, success, error, info }

/// Base responsive dialog widget with Kanjad theming
class KanJadDialog extends StatelessWidget {
  final DialogType type;
  final IconData icon;
  final String title;
  final String content;
  final List<Widget> actions;

  const KanJadDialog({
    super.key,
    required this.type,
    required this.icon,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 800;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWideScreen ? 500 : screenSize.width * 0.9,
          maxHeight: screenSize.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Styles.rouge.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and title
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Styles.rouge.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Styles.rouge,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Styles.bleu,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog for delete/confirm actions
class KanJadConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const KanJadConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirmer',
    this.cancelText = 'Annuler',
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return KanJadDialog(
      type: DialogType.confirmation,
      icon: Icons.warning_amber_rounded,
      title: title,
      content: content,
      actions: [
        SizedBox(
          width: 120,
          child: TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              cancelText,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.rouge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Loading dialog with descriptive text
class KanJadLoadingDialog extends StatelessWidget {
  final String title;
  final String message;

  const KanJadLoadingDialog({
    super.key,
    this.title = 'Chargement en cours',
    this.message = 'Veuillez patienter...',
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 800;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWideScreen ? 400 : screenSize.width * 0.8,
        ),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Styles.rouge.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Styles.rouge),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Styles.bleu,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Success feedback dialog
class KanJadSuccessDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final VoidCallback onPressed;

  const KanJadSuccessDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText = 'Continuer',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return KanJadDialog(
      type: DialogType.success,
      icon: Icons.check_circle_outline,
      title: title,
      content: content,
      actions: [
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.rouge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Error feedback dialog
class KanJadErrorDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final VoidCallback onPressed;

  const KanJadErrorDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText = 'Réessayer',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return KanJadDialog(
      type: DialogType.error,
      icon: Icons.error_outline,
      title: title,
      content: content,
      actions: [
        SizedBox(
          width: 120,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Styles.rouge),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Styles.rouge,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Information dialog
class KanJadInfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final VoidCallback onPressed;
  final IconData? icon;

  const KanJadInfoDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText = 'Compris',
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return KanJadDialog(
      type: DialogType.info,
      icon: icon ?? Icons.info_outline,
      title: title,
      content: content,
      actions: [
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.rouge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

    

/// Dialog with a text input field
class KanJadInputViewsDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final int initialValue;

  const KanJadInputViewsDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Valider',
    this.cancelText = 'Annuler',
    this.initialValue = 100,
  });

  @override
  State<KanJadInputViewsDialog> createState() => _KanJadInputViewsDialogState();
}

class _KanJadInputViewsDialogState extends State<KanJadInputViewsDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_formKey.currentState!.validate()) {
      final value = int.tryParse(_controller.text);
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 800;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWideScreen ? 500 : screenSize.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Styles.rouge.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Styles.rouge,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.star_rate_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Styles.bleu,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.content,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '100',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Styles.rouge, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une valeur';
                        }
                        final n = int.tryParse(value);
                        if (n == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        if (n < 100) {
                          return 'Doit être >= 100';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          widget.cancelText,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed: _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Styles.rouge,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: Text(widget.confirmText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Service class for easy dialog management
class DialogService {
  /// Show confirmation dialog
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => KanJadConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  /// Show loading dialog
  static Future<T?> showLoadingDialog<T>(
    BuildContext context,
    Future<T> future, {
    String title = 'Chargement en cours',
    String message = 'Veuillez patienter...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KanJadLoadingDialog(
        title: title,
        message: message,
      ),
    );

    return future.whenComplete(() => Navigator.of(context).pop()).catchError((error) {
      Navigator.of(context).pop();
      return Future<T>.error(error);
    });
  }

  /// Show success dialog
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String content,
    String buttonText = 'Continuer',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KanJadSuccessDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String content,
    String buttonText = 'Réessayer',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KanJadErrorDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show information dialog
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
    String buttonText = 'Compris',
    IconData? icon,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KanJadInfoDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        icon: icon,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
