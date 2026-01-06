import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/widgets/order_slip_sheet.dart';
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
                const SizedBox(width: 8),
                _LegendItem(color: Colors.red, label: l10n.occupied),
                const SizedBox(width: 8),
                _LegendItem(color: Colors.orange, label: l10n.reserved),
                const Spacer(),
                if (isEditMode)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(editModeProvider.notifier).state = false;
                    },
                    icon: const Icon(Icons.check),
                    label: Text(l10n.done),
                  ),
              ],
            ),
          ),
          if (isEditMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getEditHint(language),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
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
                      _showTableActions(context, ref, table, tables, l10n),
                  onTableMoved: (tableId, posX, posY, tableSizePercentX,
                      tableSizePercentY) {
                    ref.read(tablesProvider.notifier).updatePosition(
                          tableId,
                          posX,
                          posY,
                          tableSizePercentX,
                          tableSizePercentY,
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

  String _getEditHint(AppLanguage language) {
    return switch (language) {
      AppLanguage.italian =>
        'Trascina i tavoli. Avvicinali per unirli automaticamente!',
      AppLanguage.english =>
        'Drag tables. Move them close together to join automatically!',
      AppLanguage.chinese => '拖动桌子。靠近时会自动合并！',
    };
  }

  void _showAddTableDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              // Usa la dimensione dei tavoli esistenti, o 10 come default
              final existingSize = tables.isNotEmpty ? tables.first.width : 10.0;
              
              double posX = 5;
              double posY = 5;
              for (int i = 0; i <= tables.length; i++) {
                posX = (i % 5) * (existingSize + 6) + 5;
                posY = (i ~/ 5) * (existingSize + 6) + 5;
              }

              final table = TableModel(
                id: const Uuid().v4(),
                name: nameController.text.isNotEmpty
                    ? nameController.text
                    : 'T${tables.length + 1}',
                capacity: int.tryParse(capacityController.text) ?? 4,
                status: TableStatus.available,
                posX: posX,
                posY: posY,
                width: existingSize,
                height: existingSize,
              );
              ref.read(tablesProvider.notifier).addTable(table);
              Navigator.pop(context);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _showTableActions(BuildContext context, WidgetRef ref, TableModel table,
      List<TableModel> allTables, AppLocalizations l10n) {
    final language = ref.read(languageProvider);

    // If table is occupied, open the order slip directly
    if (table.status == TableStatus.occupied) {
      final order =
          ref.read(ordersProvider.notifier).getActiveOrderForTable(table.id);
      if (order != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OrderSlipSheet(table: table, order: order),
        );
        return;
      }
    }

    // Get group info
    List<TableModel> groupTables = [];
    int totalCapacity = table.capacity;
    String displayName = table.name;

    if (table.groupId != null) {
      groupTables =
          allTables.where((t) => t.groupId == table.groupId).toList();
      totalCapacity = groupTables.fold(0, (sum, t) => sum + t.capacity);
      displayName = groupTables.map((t) => t.name).join('+');
    }

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
                  if (table.isGrouped)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.link,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: table.status, l10n: l10n),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$totalCapacity ${l10n.seats}${table.isGrouped ? ' (${_getJoinedLabel(language)})' : ''}',
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
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (table.isGrouped)
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(tablesProvider.notifier)
                            .separateGroup(table.groupId!);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.link_off),
                      label: Text(_getSeparateLabel(language)),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditTableDialog(context, ref, table, l10n);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.edit),
                  ),
                  if (!table.isGrouped)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(tablesProvider.notifier).deleteTable(table.id);
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.delete,
                          color: Theme.of(context).colorScheme.error),
                      label: Text(
                        l10n.delete,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
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

  String _getJoinedLabel(AppLanguage language) {
    return switch (language) {
      AppLanguage.italian => 'uniti',
      AppLanguage.english => 'joined',
      AppLanguage.chinese => '已合并',
    };
  }

  String _getSeparateLabel(AppLanguage language) {
    return switch (language) {
      AppLanguage.italian => 'Separa',
      AppLanguage.english => 'Separate',
      AppLanguage.chinese => '分开',
    };
  }

  void _showEditTableDialog(BuildContext context, WidgetRef ref,
      TableModel table, AppLocalizations l10n) {
    final nameController = TextEditingController(text: table.name);
    final capacityController =
        TextEditingController(text: table.capacity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              );
              ref.read(tablesProvider.notifier).updateTable(updated);
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
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

class _FloorPlan extends ConsumerStatefulWidget {
  final List<TableModel> tables;
  final bool isEditMode;
  final AppLocalizations l10n;
  final void Function(TableModel) onTableTap;
  final void Function(String tableId, double posX, double posY,
      double tableSizePercentX, double tableSizePercentY) onTableMoved;

  const _FloorPlan({
    required this.tables,
    required this.isEditMode,
    required this.l10n,
    required this.onTableTap,
    required this.onTableMoved,
  });

  @override
  ConsumerState<_FloorPlan> createState() => _FloorPlanState();
}

class _FloorPlanState extends ConsumerState<_FloorPlan> {
  String? _draggingTableId;
  String? _snapTargetId;

  @override
  Widget build(BuildContext context) {
    // Group tables by groupId for visual connection
    final groups = <String, List<TableModel>>{};
    for (final table in widget.tables) {
      if (table.groupId != null) {
        groups.putIfAbsent(table.groupId!, () => []).add(table);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final floorWidth = constraints.maxWidth;
        final floorHeight = constraints.maxHeight;

        return Container(
          width: floorWidth,
          height: floorHeight,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isEditMode
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: widget.isEditMode ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.isEditMode)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPainter(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              // Draw group backgrounds
              ...groups.entries.map((entry) {
                final groupTables = entry.value;
                if (groupTables.length < 2) return const SizedBox.shrink();

                final actualFloorWidth = floorWidth - 16;
                final actualFloorHeight = floorHeight - 16;
                // Dimensione fissa dei tavoli in pixel
                const double tablePixelSize = 60.0;

                // Calcola bounding box in pixel
                double minLeft = double.infinity;
                double minTop = double.infinity;
                double maxRight = 0;
                double maxBottom = 0;

                for (final t in groupTables) {
                  final tLeft = (t.posX / 100) * actualFloorWidth;
                  final tTop = (t.posY / 100) * actualFloorHeight;
                  if (tLeft < minLeft) minLeft = tLeft;
                  if (tTop < minTop) minTop = tTop;
                  if (tLeft + tablePixelSize > maxRight) {
                    maxRight = tLeft + tablePixelSize;
                  }
                  if (tTop + tablePixelSize > maxBottom) {
                    maxBottom = tTop + tablePixelSize;
                  }
                }

                return Positioned(
                  left: minLeft - 4,
                  top: minTop - 4,
                  child: Container(
                    width: maxRight - minLeft + 8,
                    height: maxBottom - minTop + 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                  ),
                );
              }),
              // Tables
              ...widget.tables.map((table) {
                final actualFloorWidth = floorWidth - 16;
                final actualFloorHeight = floorHeight - 16;
                // Dimensione fissa dei tavoli in pixel
                const double tablePixelSize = 60.0;
                // Calcola le percentuali separate per X e Y
                final tableSizePercentX =
                    (tablePixelSize / actualFloorWidth) * 100;
                final tableSizePercentY =
                    (tablePixelSize / actualFloorHeight) * 100;

                final left = (table.posX / 100) * actualFloorWidth;
                final top = (table.posY / 100) * actualFloorHeight;

                final isSnapTarget = _snapTargetId == table.id;

                return Positioned(
                  left: left,
                  top: top,
                  child: widget.isEditMode
                      ? Draggable<TableModel>(
                          data: table,
                          feedback: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(8),
                            child: _TableWidget(
                              table: table,
                              size: tablePixelSize,
                              isDragging: true,
                              willSnap: false, // Il feedback non può aggiornarsi
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _TableWidget(
                              table: table,
                              size: tablePixelSize,
                            ),
                          ),
                          onDragStarted: () {
                            setState(() {
                              _draggingTableId = table.id;
                              _snapTargetId = null;
                            });
                          },
                          onDragUpdate: (details) {
                            final RenderBox? box =
                                context.findRenderObject() as RenderBox?;
                            if (box == null) return;
                            
                            final localPos =
                                box.globalToLocal(details.globalPosition);

                            // Centra la posizione sul cursore
                            double newPosX =
                                ((localPos.dx - tablePixelSize / 2) / actualFloorWidth) * 100;
                            double newPosY =
                                ((localPos.dy - tablePixelSize / 2) / actualFloorHeight) * 100;

                            final snapTarget = ref
                                .read(tablesProvider.notifier)
                                .checkSnapTarget(table.id, newPosX, newPosY,
                                    tableSizePercentX, tableSizePercentY);

                            if (snapTarget != _snapTargetId) {
                              setState(() {
                                _snapTargetId = snapTarget;
                              });
                            }
                          },
                          onDragEnd: (details) {
                            final RenderBox? box =
                                context.findRenderObject() as RenderBox?;
                            if (box == null) return;
                            
                            final localPos = box.globalToLocal(details.offset);

                            double newPosX =
                                (localPos.dx / actualFloorWidth) * 100;
                            double newPosY =
                                (localPos.dy / actualFloorHeight) * 100;

                            newPosX = newPosX.clamp(0, 100 - tableSizePercentX);
                            newPosY = newPosY.clamp(0, 100 - tableSizePercentY);

                            widget.onTableMoved(table.id, newPosX, newPosY,
                                tableSizePercentX, tableSizePercentY);

                            setState(() {
                              _draggingTableId = null;
                              _snapTargetId = null;
                            });
                          },
                          onDraggableCanceled: (_, __) {
                            setState(() {
                              _draggingTableId = null;
                              _snapTargetId = null;
                            });
                          },
                          child: _TableWidget(
                            table: table,
                            size: tablePixelSize,
                            onTap: () => widget.onTableTap(table),
                            isSnapTarget: isSnapTarget,
                          ),
                        )
                      : _TableWidget(
                          table: table,
                          size: tablePixelSize,
                          onTap: () => widget.onTableTap(table),
                        ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _TableWidget extends StatelessWidget {
  final TableModel table;
  final double size; // Tavolo quadrato
  final VoidCallback? onTap;
  final bool isDragging;
  final bool isSnapTarget;
  final bool willSnap;

  const _TableWidget({
    required this.table,
    required this.size,
    this.onTap,
    this.isDragging = false,
    this.isSnapTarget = false,
    this.willSnap = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (table.status) {
      TableStatus.available => Colors.green,
      TableStatus.occupied => Colors.red,
      TableStatus.reserved => Colors.orange,
      TableStatus.cleaning => Colors.blue,
    };

    // Colore speciale quando è target di snap
    final borderColor = isSnapTarget ? Colors.amber : color;
    final borderWidth = isSnapTarget ? 3.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSnapTarget
              ? Colors.amber.withOpacity(0.4)
              : willSnap
                  ? Colors.amber.withOpacity(0.6)
                  : color.withOpacity(isDragging ? 0.9 : 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isDragging || isSnapTarget
              ? [
                  BoxShadow(
                    color: (willSnap || isSnapTarget ? Colors.amber : color)
                        .withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: isSnapTarget ? 4 : 2,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (willSnap || isSnapTarget)
                Icon(
                  Icons.link,
                  size: size > 50 ? 16 : 12,
                  color: Colors.amber.shade800,
                ),
              Text(
                table.name,
                style: TextStyle(
                  color: isSnapTarget || willSnap
                      ? Colors.amber.shade900
                      : color.computeLuminance() > 0.5
                          ? Colors.black87
                          : isDragging
                              ? Colors.white
                              : color,
                  fontWeight: FontWeight.bold,
                  fontSize: size > 50 ? 13 : 11,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (!willSnap && !isSnapTarget)
                // Show number of people if occupied, otherwise show capacity
                table.status == TableStatus.occupied && table.numberOfPeople != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: size > 50 ? 12 : 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${table.numberOfPeople}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: size > 50 ? 11 : 9,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '${table.capacity}',
                        style: TextStyle(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black54
                              : isDragging
                                  ? Colors.white70
                                  : color.withOpacity(0.8),
                          fontSize: size > 50 ? 11 : 9,
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
