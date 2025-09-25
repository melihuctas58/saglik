import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../utils/risk_colors.dart';

class RiskGauge extends StatelessWidget {
  final int score; // 0..1000
  final String level; // red/yellow/green/other
  const RiskGauge({super.key, required this.score, required this.level});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = score.clamp(0, 1000).toDouble();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Risk Göstergesi', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: SfRadialGauge(
              enableLoadingAnimation: true,
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 1000,
                  showTicks: false,
                  showLabels: false,
                  axisLineStyle: AxisLineStyle(
                    thicknessUnit: GaugeSizeUnit.factor,
                    thickness: 0.12,
                    color: cs.outlineVariant,
                  ),
                  ranges: <GaugeRange>[
                    GaugeRange(
                      startValue: 0,
                      endValue: 250,
                      color: riskColorOf('green'),
                      startWidth: 20,
                      endWidth: 20,
                    ),
                    GaugeRange(
                      startValue: 250,
                      endValue: 400,
                      color: riskColorOf('yellow'),
                      startWidth: 20,
                      endWidth: 20,
                    ),
                    GaugeRange(
                      startValue: 400,
                      endValue: 1000,
                      color: riskColorOf('red'),
                      startWidth: 20,
                      endWidth: 20,
                    ),
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(
                      value: v,
                      needleStartWidth: 0.5,
                      needleEndWidth: 3,
                      knobStyle: const KnobStyle(knobRadius: 0.06),
                      tailStyle: const TailStyle(length: 0.15, width: 2),
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score / 1000',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: riskColorOf(level).withOpacity(.12),
                              border: Border.all(color: riskColorOf(level).withOpacity(.35)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              level.toUpperCase(),
                              style: TextStyle(color: riskColorOf(level), fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      positionFactor: 0.1,
                      angle: 90,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}