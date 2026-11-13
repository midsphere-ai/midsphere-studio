import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/dialog.dart';
import 'package:flutter/material.dart' show Badge;
import 'package:flutter_client/logics/domain/entities/billing/ticket.dart';
import 'package:flutter_client/logics/domain/usecases/billing/billing_usecase.dart';
import 'package:flutter_client/logics/domain/entities/base/repo.dart';
import 'package:flutter_client/pages/support/create_ticket.dart';
import 'package:flutter_client/pages/support/ticket_details.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';
import 'package:flutter_client/widgets/builders/item_builder_list_card.dart';
import 'package:flutter_client/widgets/state/simple_bloc.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final String blocKey = "support_tickets_bloc";

  @override
  Widget build(BuildContext context) {
    return LimitedWindowBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Support Tickets").h3,
                PrimaryButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => const CreateTicketDialog(),
                    );
                  },
                  child: const Text("New Ticket"),
                ),
              ],
            ),
          ),
          Expanded(
            child: ItemBuilderBlocCard(
              blocKey: blocKey,
              paginated: true,
              customHeight: 200,
              dataSource: Billing.getTickets,
              dataSourceArgs: const {},
              onError: "Failed to load support tickets",
              onDataEmpty: "No support tickets found",
              placeHolderItems: List.generate(
                6,
                (index) => Ticket(
                  id: "placeholder",
                  title: "Placeholder Ticket",
                  message: "This is a placeholder message",
                  status: "open",
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ),
              item: (Ticket ticket) => _buildTicketCard(context, ticket),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Ticket ticket) {
    Color statusColor;
    switch (ticket.status.toLowerCase()) {
      case 'open':
        statusColor = Colors.green;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'resolved':
        statusColor = Colors.purple;
        break;
      case 'closed':
        statusColor = Colors.gray;
        break;
      default:
        statusColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: GhostButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => TicketDetailsDialog(ticket: ticket),
          );

        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).h4,
                  ),
                  Badge(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  ticket.message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ).small.muted,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.mutedForeground,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: Theme.of(context).colorScheme.mutedForeground,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
