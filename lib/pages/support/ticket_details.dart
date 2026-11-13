import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/billing/ticket.dart';
import 'package:flutter_client/logics/domain/usecases/billing/billing_usecase.dart';

class TicketDetailsDialog extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsDialog({super.key, required this.ticket});

  @override
  State<TicketDetailsDialog> createState() => _TicketDetailsDialogState();
}

class _TicketDetailsDialogState extends State<TicketDetailsDialog> {
  late Ticket ticket;
  bool isEditing = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    ticket = widget.ticket;
    _titleController.text = ticket.title;
    _messageController.text = ticket.message;
    _statusController.text = ticket.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        width: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isEditing)
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      placeholder: Text("Title"),
                    ),
                  )
                else
                  Text(ticket.title).h3,
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("ID: ${ticket.id}").small.muted,
            const SizedBox(height: 16),
            if (isEditing)
               Column(
                children: [
                  TextField(controller: _messageController, maxLines: 5, placeholder: Text("Message")),
                  const SizedBox(height: 8),
                  TextField(controller: _statusController, placeholder: Text("Status")),
                ],
               )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Status: ${ticket.status}"),
                  const SizedBox(height: 8),
                  Text(ticket.message),
                ],
              ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isEditing)
                  GhostButton(
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                    child: const Text("Edit"),
                  ),

                 if (!isEditing)
                  DestructiveButton(
                    onPressed: _deleteTicket,
                    child: const Text("Delete"),
                  ),

                if (isEditing) ...[
                   GhostButton(
                    onPressed: () {
                      setState(() {
                        isEditing = false;
                        _titleController.text = ticket.title;
                        _messageController.text = ticket.message;
                        _statusController.text = ticket.status;
                      });
                    },
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    onPressed: isLoading ? null : _updateTicket,
                    child: isLoading ? const CircularProgressIndicator() : const Text("Save"),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTicket() async {
     setState(() {
      isLoading = true;
    });
    try {
      await Billing.updateTicket(
        ticketId: ticket.id,
        title: _titleController.text,
        message: _messageController.text,
        status: _statusController.text,
      );
       if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('$e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteTicket() async {
    setState(() {
      isLoading = true;
    });
    try {
      await Billing.deleteTicket(ticketId: ticket.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('$e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
