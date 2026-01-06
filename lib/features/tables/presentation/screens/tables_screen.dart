import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../data/models/table_model.dart';
import '../providers/tables_provider.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);
    final isEditMode = ref.watch(editModeProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _LegendItem(color: Colors.green, label: l10n.available),
                const SizedBox(width: 12),
                _LegendItem(color: Colors.red, label: l10n.occupied),
                const SizedBox(width: 12),
                _LegendItem(color: Colors.orange, label: l10n.reserved),
                const SizedBox(width: 12),
                _LegendItem(color: Colors.blue, label: l10n.cleaning),
                const Spacer(),
                if (isEditMode)
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(editModeProvider.notifier).state = false,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.done),
                  ),
              ],
            ),
          ),
          Expanded(
            child: tablesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (tables) {
                if (tables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noTables,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return _FloorPlan(
                  tables: tables,
                  isEditMode: isEditMode,
                  l10n: l10n,
                  onTableTap: (table) =>
                      _showTableActions(context, ref, table, l10n),
                  onTableMoved: (tableId, posX, posY) {
                    ref.read(tablesProvider.notifier).updatePosition(
                          tableId,
                          posX,
                          posY,
                        );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'edit',
            onPressed: () {
              ref.read(editModeProvider.notifier).state = !isEditMode;
            },
            backgroundColor: isEditMode
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Icon(isEditMode ? Icons.lock_open : Icons.edit),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _showAddTableDialog(context, ref, l10n),
            icon: const Icon(Icons.add),
            label: Text(l10n.table),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController(text: '4');
    TableShape selectedShape = TableShape.square;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.addTable),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '${l10n.name} (T1, T2...)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                decoration: InputDecoration(labelText: l10n.seats),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SegmentedButton<TableShape>(
                segments: [
                  ButtonSegment(
                    value: TableShape.square,
                    icon: const Icon(Icons.square_outlined),
                    label: Text(l10n.square),
                  ),
                  ButtonSegment(
                    value: TableShape.round,
                    icon: const Icon(Icons.circle_outlined),
                    label: Text(l10n.round),
                  ),
                  ButtonSegment(
                    value: TableShape.rectangle,
                    icon: const Icon(Icons.rectangle_outlined),
                    label: Text(l10n.rectangle),
                  ),
                ],
                selected: {selectedShape},
                onSelectionChanged: (shapes) {
                  setState(() => selectedShape = shapes.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final tables = ref.read(tablesProvider).valueOrNull ?? [];
                double posX = 10;
                double posY = 10;
                for (int i = 0; i < tables.length; i++) {
                  posX = (i % 4) * 22 + 10;
                  posY = (i ~/ 4) * 22 + 10;
                }

                final table = TableModel(
                  id: const Uuid().v4(),
                  name: nameController.text.isNotEmpty
                      ? nameController.text
                      : 'T${tables.length + 1}',
                  capacity: int.tryParse(capacityController.text) ?? 4,
                  status: TableStatus.available,
                  shape: selectedShape,
                  posX: posX,
                  posY: posY,
                  width: selectedShape == TableShape.rectangle ? 18 : 12,
                  height: 12,
                );
                ref.read(tablesProvider.notifier).addTable(table);
                Navigator.pop(context);
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  void _showTableActions(BuildContext context, WidgetRef ref, TableModel table,
      AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: table.status, l10n: l10n),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${table.capacity} ${l10n.seats}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (table.reservedBy != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${l10n.reserved}: ${table.reservedBy}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (table.status != TableStatus.available)
                    FilledButton.tonal(
                      onPressed: () {
                        ref
                            .read(tablesProvider.notifier)
                            .updateStatus(table.id, TableStatus.available);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.markAvailable),
                    ),
                  if (table.status == TableStatus.available)
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(tablesProvider.notifier)
                            .updateStatus(table.id, TableStatus.occupied);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.markOccupied),
                    ),
                  if (table.status == TableStatus.available)
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(context);
                        _showReservationDialog(context, ref, table, l10n);
                      },
                      child: Text(l10n.reserve),
                    ),
                  if (table.status == TableStatus.occupied)
                    FilledButton.tonal(
                      onPressed: () {
                        ref
                            .read(tablesProvider.notifier)
                            .updateStatus(table.id, TableStatus.cleaning);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.needsCleaning),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditTableDialog(context, ref, table, l10n);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.edit),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(tablesProvider.notifier).deleteTable(table.id);
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.delete,
                        color: Theme.of(context).colorScheme.error),
                    label: Text(
                      l10n.delete,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditTableDialog(BuildContext context, WidgetRef ref,
      TableModel table, AppLocalizations l10n) {
    final nameController = TextEditingController(text: table.name);
    final capacityController =
        TextEditingController(text: table.capacity.toString());
    TableShape selectedShape = table.shape;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.edit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.name),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                decoration: InputDecoration(labelText: l10n.seats),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SegmentedButton<TableShape>(
                segments: [
                  ButtonSegment(
                    value: TableShape.square,
                    icon: const Icon(Icons.square_outlined),
                  ),
                  ButtonSegment(
                    value: TableShape.round,
                    icon: const Icon(Icons.circle_outlined),
                  ),
                  ButtonSegment(
                    value: TableShape.rectangle,
                    icon: const Icon(Icons.rectangle_outlined),
                  ),
                ],
                selected: {selectedShape},
                onSelectionChanged: (shapes) {
                  setState(() => selectedShape = shapes.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final updated = table.copyWith(
                  name: nameController.text,
                  capacity: int.tryParse(capacityController.text) ?? 4,
                  shape: selectedShape,
                  width: selectedShape == TableShape.rectangle ? 18 : 12,
                );
                ref.read(tablesProvider.notifier).updateTable(updated);
                Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showReservationDialog(BuildContext context, WidgetRef ref,
      TableModel table, AppLocalizations l10n) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reservation),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: l10n.customerName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(tablesProvider.notifier).makeReservation(
                    table.id,
                    nameController.text,
                    DateTime.now(),
                  );
              Navigator.pop(context);
            },
            child: Text(l10n.reserve),
          ),
        ],
      ),
    );
  }
}

class _FloorPlan extends StatelessWidget {
  final List<TableModel> tables;
  final bool isEditMode;
  final AppLocalizations l10n;
  final void Function(TableModel) onTableTap;
  final void Function(String tableId, double posX, double posY) onTableMoved;

  const _FloorPlan({
    required this.tables,
    required this.isEditMode,
    required this.l10n,
    required this.onTableTap,
    required this.onTableMoved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditMode
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: isEditMode ? 2 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final floorWidth = constraints.maxWidth;
          final floorHeight = constraints.maxHeight;

          return Stack(
            children: [
              if (isEditMode)
                CustomPaint(
                  size: Size(floorWidth, floorHeight),
                  painter: _GridPainter(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ...tables.map((table) {
                final left = (table.posX / 100) * floorWidth;
                final top = (table.posY / 100) * floorHeight;
                final width = (table.width / 100) * floorWidth;
                final height = (table.height / 100) * floorHeight;

                return Positioned(
                  left: left,
                  top: top,
                  child: isEditMode
                      ? Draggable<TableModel>(
                          data: table,
                          feedback: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(
                              table.shape == TableShape.round ? 100 : 8,
                            ),
                            child: _TableWidget(
                              table: table,
                              width: width,
                              height: height,
                              isDragging: true,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _TableWidget(
                              table: table,
                              width: width,
                              height: height,
                            ),
                          ),
                          onDragEnd: (details) {
                            final RenderBox box =
                                context.findRenderObject() as RenderBox;
                            final localPos = box.globalToLocal(details.offset);

                            double newPosX = (localPos.dx / floorWidth) * 100;
                            double newPosY = (localPos.dy / floorHeight) * 100;

                            newPosX = newPosX.clamp(0, 100 - table.width);
                            newPosY = newPosY.clamp(0, 100 - table.height);

                            onTableMoved(table.id, newPosX, newPosY);
                          },
                          child: _TableWidget(
                            table: table,
                            width: width,
                            height: height,
                            onTap: () => onTableTap(table),
                          ),
                        )
                      : _TableWidget(
                          table: table,
                          width: width,
                          height: height,
                          onTap: () => onTableTap(table),
                        ),
                );
              }),
              if (isEditMode)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        l10n.dragToPosition,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TableWidget extends StatelessWidget {
  final TableModel table;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool isDragging;

  const _TableWidget({
    required this.table,
    required this.width,
    required this.height,
    this.onTap,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (table.status) {
      TableStatus.available => Colors.green,
      TableStatus.occupied => Colors.red,
      TableStatus.reserved => Colors.orange,
      TableStatus.cleaning => Colors.blue,
    };

    final borderRadius = table.shape == TableShape.round
        ? BorderRadius.circular(100)
        : BorderRadius.circular(8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(isDragging ? 0.8 : 0.2),
          borderRadius: borderRadius,
          border: Border.all(color: color, width: 2),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                table.name,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: width > 60 ? 14 : 11,
                ),
              ),
              Text(
                '${table.capacity}p',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: width > 60 ? 11 : 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TableStatus status;
  final AppLocalizations l10n;

  const _StatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      TableStatus.available => (Colors.green, l10n.available),
      TableStatus.occupied => (Colors.red, l10n.occupied),
      TableStatus.reserved => (Colors.orange, l10n.reserved),
      TableStatus.cleaning => (Colors.blue, l10n.cleaning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += size.width / 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += size.height / 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
