import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/usecases/billing/billing_usecase.dart';

class CreateTicketDialog extends StatefulWidget {
  const CreateTicketDialog({super.key});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create Ticket").h3,
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              placeholder: Text("Title"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              placeholder: Text("Message"),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GhostButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                PrimaryButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Submit"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await Billing.createTicket(
        title: _titleController.text,
        message: _messageController.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error
      debugPrint('$e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
