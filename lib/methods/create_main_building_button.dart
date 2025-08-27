import 'package:flutter/material.dart';
import 'package:whc_proto/building_class.dart';

import 'package:whc_proto/widgets/floor_button.dart';

class CreateMainBuildingButton extends StatelessWidget {
  const CreateMainBuildingButton({super.key, required this.buildingId});

  final String buildingId;

  @override
  Widget build(BuildContext context) {

    String buildingName = getBuildingName(buildingId);
    String buildingInfo = getBuildingInfo(buildingId);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.business_center, size: 24.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(buildingName),
                    const SizedBox(height: 4.0),
                    Text(
                      buildingInfo,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                  for (var floor in getBuildingFloors(buildingId)) ...{
                    FloorButton(floorNum: floor, buildingId: buildingId),
                    const SizedBox(width: 8.0),
                  }
              ],
            ),
          ),
        ],
      ),
    );
  }
}
