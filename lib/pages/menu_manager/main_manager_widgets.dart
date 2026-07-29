import 'package:flutter/material.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/invoice_carrier.dart';
import 'package:receipt_fold/pages/menu_manager/tab_barcode_view.dart';

class MobileItemCard extends StatelessWidget {
  final MobileBarcodeItem item;
  final VoidCallback? onTap;

  const MobileItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minTileHeight: 0,
        title: Text(item.code, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.name ?? '', overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    );
  }
}

class MemberItemCard extends StatelessWidget {
  final MemberBarcodeItem item;
  final VoidCallback? onTap;

  const MemberItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        minTileHeight: 0,
        title: Text(item.name ?? '', overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.code, overflow: TextOverflow.ellipsis),
            Text(item.format.locale, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: ImageBox(item: item, nullNeedBuild: false),
      ),
    );
  }
}

class CarrierCard extends StatelessWidget {
  final InvoiceCarrier carrier;
  final VoidCallback? onTap;

  const CarrierCard({super.key, required this.carrier, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        minTileHeight: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(carrier.name, overflow: TextOverflow.ellipsis),
            ),
            Text(
              carrier.carrierTypeName ?? carrier.carrierType ?? '',
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              color: colorScheme.surfaceContainerHigh,
              elevation: 0,
              margin: const EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  carrier.status.locale,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: textTheme.bodySmall?.fontSize,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                carrier.carrierId2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
