import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

typedef TelemetryGetter =
    List<dynamic> Function(Map<String, dynamic> driverObj);

enum ChartStyle { line, area, scatter }

class TelemetryLineChartBase extends StatefulWidget {
  final dynamic payload;

  final List<dynamic> x;

  final String xType;

  final Map<String, dynamic> series;

  final List<String> enabledCodes;

  final String title;
  final IconData icon;

  final String factorKey;

  final TelemetryGetter getValues;

  final String Function(num v) formatValue;

  final String? Function(num? v)? badgeForValue;

  final bool isStep;

  final bool clamp0to100;

  final double sparkHeight;

  final double expandedHeight;

  const TelemetryLineChartBase({
    super.key,
    required this.payload,
    required this.x,
    required this.xType,
    required this.series,
    required this.enabledCodes,
    required this.title,
    required this.icon,
    required this.factorKey,
    required this.getValues,
    required this.formatValue,
    this.badgeForValue,
    this.isStep = false,
    this.clamp0to100 = false,
    this.sparkHeight = 70,
    this.expandedHeight = 220,
  });

  @override
  State<TelemetryLineChartBase> createState() => _TelemetryLineChartBaseState();
}

class _TelemetryLineChartBaseState extends State<TelemetryLineChartBase>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  ChartStyle _chartStyle = ChartStyle.line;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final ScrollController _barScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Color _getIconColor() {
    switch (widget.factorKey) {
      case 'speed':
        return Colors.red.shade400;
      case 'drs':
        return Colors.red.shade400;
      case 'throttle':
        return Colors.red.shade400;
      case 'brake':
        return Colors.red.shade400;
      case 'engine_rpm':
        return Colors.red.shade400;
      case 'gear':
        return Colors.red.shade400;
      default:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastIdx = widget.x.isNotEmpty ? widget.x.length - 1 : 0;

    num? current;
    int n = 0;

    for (final code in widget.enabledCodes) {
      final dObj = _asMap(widget.series[code]);
      final vals = widget.getValues(dObj);
      if (vals.isEmpty) continue;
      if (lastIdx < 0 || lastIdx >= vals.length) continue;

      final v = vals[lastIdx];
      if (v is num) {
        current = (current ?? 0) + v;
        n++;
      }
    }
    if (current != null && n > 0) current = current! / n;

    final badge = widget.badgeForValue?.call(current);
    final iconColor = _getIconColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withOpacity(0.8),
                        iconColor.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (widget.enabledCodes.isNotEmpty)
                        Text(
                          "${widget.enabledCodes.length} driver${widget.enabledCodes.length > 1 ? 's' : ''} active",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                    ],
                  ),
                ),
                if (badge != null) _badge(badge, iconColor),
                const SizedBox(width: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: current?.toDouble() ?? 0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Text(
                      current == null ? "—" : widget.formatValue(value.round()),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: iconColor,
                        shadows: [
                          Shadow(
                            color: iconColor.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded ? "Collapse" : "Expand",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildChartStyleSelector(),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: widget.sparkHeight,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.none,
              child: _buildChart(compact: true),
            ),
            SizeTransition(
              sizeFactor: _animation,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  height: widget.expandedHeight,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.none,
                  child: _buildChart(compact: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartStyleSelector() {
    return PopupMenuButton<ChartStyle>(
      initialValue: _chartStyle,
      onSelected: (style) => setState(() => _chartStyle = style),
      offset: const Offset(0, 40),
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getChartStyleIcon(), size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildStyleMenuItem(ChartStyle.line, Icons.show_chart, "Line"),
        _buildStyleMenuItem(ChartStyle.area, Icons.area_chart, "Area"),
        _buildStyleMenuItem(ChartStyle.scatter, Icons.scatter_plot, "Scatter"),
      ],
    );
  }

  PopupMenuItem<ChartStyle> _buildStyleMenuItem(
    ChartStyle style,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<ChartStyle>(
      value: style,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _chartStyle == style ? Colors.redAccent : Colors.white70,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: _chartStyle == style ? Colors.redAccent : Colors.white,
              fontWeight: _chartStyle == style
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChartStyleIcon() {
    switch (_chartStyle) {
      case ChartStyle.line:
        return Icons.show_chart;
      case ChartStyle.area:
        return Icons.area_chart;
      case ChartStyle.scatter:
        return Icons.scatter_plot;
    }
  }

  Widget _buildChart({required bool compact}) {
    switch (_chartStyle) {
      case ChartStyle.line:
        return _buildLineChart(compact: compact);
      case ChartStyle.area:
        return _buildAreaChart(compact: compact);
      case ChartStyle.scatter:
        return _buildScatterChart(compact: compact);
      case ChartStyle.scatter:
        return _buildScatterChart(compact: compact);
    }
  }

  Widget _buildLineChart({required bool compact}) {
    if (widget.x.isEmpty || widget.enabledCodes.isEmpty) {
      return _buildEmptyState();
    }

    final bars = <LineChartBarData>[];
    double? minY;
    double? maxY;

    final step = compact ? math.max(1, (widget.x.length / 120).floor()) : 1;

    for (final code in widget.enabledCodes) {
      final dObj = _asMap(widget.series[code]);
      final vals = widget.getValues(dObj);

      if (vals.isEmpty) continue;

      final spots = <FlSpot>[];
      for (int i = 0; i < widget.x.length && i < vals.length; i += step) {
        final xv = widget.x[i];
        final yv = vals[i];
        if (xv is! num || yv is! num) continue;

        double y = yv.toDouble();
        if (widget.clamp0to100) y = y.clamp(0.0, 100.0);

        spots.add(FlSpot(xv.toDouble(), y));
        minY = minY == null ? y : math.min(minY!, y);
        maxY = maxY == null ? y : math.max(maxY!, y);
      }

      if (spots.isEmpty) continue;

      final color = _driverColor(widget.payload, code);

      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: !widget.isStep,
          curveSmoothness: 0.3,
          barWidth: compact ? 2.5 : 3,
          dotData: FlDotData(
            show: !compact,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          color: color,
        ),
      );
    }

    if (bars.isEmpty) return _buildEmptyState();

    final pad = (maxY! - minY!).abs() * 0.08;
    final minYp = minY! - pad;
    final maxYp = maxY! + pad;

    return _buildLineChartBase(bars, minYp, maxYp, compact);
  }

  Widget _buildAreaChart({required bool compact}) {
    if (widget.x.isEmpty || widget.enabledCodes.isEmpty) {
      return _buildEmptyState();
    }

    final bars = <LineChartBarData>[];
    double? minY;
    double? maxY;

    final step = compact ? math.max(1, (widget.x.length / 120).floor()) : 1;

    for (final code in widget.enabledCodes) {
      final dObj = _asMap(widget.series[code]);
      final vals = widget.getValues(dObj);

      if (vals.isEmpty) continue;

      final spots = <FlSpot>[];
      for (int i = 0; i < widget.x.length && i < vals.length; i += step) {
        final xv = widget.x[i];
        final yv = vals[i];
        if (xv is! num || yv is! num) continue;

        double y = yv.toDouble();
        if (widget.clamp0to100) y = y.clamp(0.0, 100.0);

        spots.add(FlSpot(xv.toDouble(), y));
        minY = minY == null ? y : math.min(minY!, y);
        maxY = maxY == null ? y : math.max(maxY!, y);
      }

      if (spots.isEmpty) continue;

      final color = _driverColor(widget.payload, code);

      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.4,
          barWidth: compact ? 2.5 : 3,
          dotData: const FlDotData(show: false),
          color: color,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.4), color.withOpacity(0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    if (bars.isEmpty) return _buildEmptyState();

    final pad = (maxY! - minY!).abs() * 0.08;
    final minYp = minY! - pad;
    final maxYp = maxY! + pad;

    return _buildLineChartBase(bars, minYp, maxYp, compact);
  }

  Widget _buildBarChartContent({required bool compact}) {
    if (widget.x.isEmpty || widget.enabledCodes.isEmpty) {
      return _buildEmptyState();
    }

    final barGroups = <BarChartGroupData>[];
    double? minY;
    double? maxY;

    final step = compact
        ? math.max(1, (widget.x.length / 40).floor())
        : math.max(1, (widget.x.length / 60).floor());
    final xLength = (widget.x.length / step).floor();

    for (int i = 0; i < xLength && i * step < widget.x.length; i++) {
      final xIdx = i * step;
      final xv = widget.x[xIdx];
      if (xv is! num) continue;

      final barGroup = BarChartGroupData(x: xv.toInt(), barRods: []);

      final rods = <BarChartRodData>[];
      int colorIdx = 0;
      for (final code in widget.enabledCodes) {
        final dObj = _asMap(widget.series[code]);
        final vals = widget.getValues(dObj);

        if (vals.isEmpty || xIdx >= vals.length) continue;

        final yv = vals[xIdx];
        if (yv is! num) continue;

        double y = yv.toDouble();
        if (widget.clamp0to100) y = y.clamp(0.0, 100.0);

        minY = minY == null ? y : math.min(minY!, y);
        maxY = maxY == null ? y : math.max(maxY!, y);

        final color = _driverColor(widget.payload, code);

        rods.add(
          BarChartRodData(
            toY: y,
            color: color,
            width: compact ? 6 : 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );
      }

      if (rods.isNotEmpty) {
        barGroups.add(BarChartGroupData(x: xv.toInt(), barRods: rods));
      }
    }

    if (barGroups.isEmpty) return _buildEmptyState();

    final pad = ((maxY ?? 100) - (minY ?? 0)).abs() * 0.1;
    final minYp = (minY ?? 0) - pad;
    final maxYp = (maxY ?? 100) + pad;

    return BarChart(
      BarChartData(
        minY: minYp.clamp(0, double.infinity),
        maxY: maxYp,
        gridData: FlGridData(
          show: !compact,
          drawVerticalLine: false,
          horizontalInterval: (maxYp - minYp) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.08),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black.withValues(alpha: 0.9),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String driverCode = '';
              if (rodIndex < widget.enabledCodes.length) {
                driverCode = widget.enabledCodes[rodIndex];
              }
              return BarTooltipItem(
                '$driverCode\n${rod.toY.toStringAsFixed(1)}',
                TextStyle(
                  color: rod.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartWithScroll({required bool compact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final requiredWidth = _calculateBarChartWidth(compact);

        final barChart = _buildBarChartContent(compact: compact);

        if (requiredWidth <= availableWidth) {
          return Align(
            alignment: Alignment.center,
            child: SizedBox(width: availableWidth, child: barChart),
          );
        }

        return SingleChildScrollView(
          controller: _barScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(width: requiredWidth, child: barChart),
        );
      },
    );
  }

  double _calculateBarChartWidth(bool compact) {
    final step = compact
        ? math.max(1, (widget.x.length / 40).floor())
        : math.max(1, (widget.x.length / 60).floor());
    final xLength = (widget.x.length / step).floor();
    final barWidth = compact ? 8.0 : 12.0;
    final spacing = 4.0;
    final minWidth = 100.0;
    return math.max(xLength * (barWidth + spacing) + 50, minWidth);
  }

  Widget _buildScatterChart({required bool compact}) {
    if (widget.x.isEmpty || widget.enabledCodes.isEmpty) {
      return _buildEmptyState();
    }

    final spots = <ScatterSpot>[];
    double? minX;
    double? maxX;
    double? minY;
    double? maxY;

    final step = compact ? math.max(1, (widget.x.length / 80).floor()) : 1;

    for (final code in widget.enabledCodes) {
      final dObj = _asMap(widget.series[code]);
      final vals = widget.getValues(dObj);

      if (vals.isEmpty) continue;

      final color = _driverColor(widget.payload, code);

      for (int i = 0; i < widget.x.length && i < vals.length; i += step) {
        final xv = widget.x[i];
        final yv = vals[i];
        if (xv is! num || yv is! num) continue;

        double y = yv.toDouble();
        if (widget.clamp0to100) y = y.clamp(0.0, 100.0);

        final x = xv.toDouble();
        spots.add(
          ScatterSpot(
            x,
            y,
            dotPainter: FlDotCirclePainter(
              radius: compact ? 4 : 6,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
        );

        minX = minX == null ? x : math.min(minX!, x);
        maxX = maxX == null ? x : math.max(maxX!, x);
        minY = minY == null ? y : math.min(minY!, y);
        maxY = maxY == null ? y : math.max(maxY!, y);
      }
    }

    if (spots.isEmpty) return _buildEmptyState();

    final padX = ((maxX ?? 1) - (minX ?? 0)).abs() * 0.08;
    final padY = ((maxY ?? 100) - (minY ?? 0)).abs() * 0.08;
    final minXp = (minX ?? 0) - padX;
    final maxXp = (maxX ?? 1) + padX;
    final minYp = (minY ?? 0) - padY;
    final maxYp = (maxY ?? 100) + padY;

    return ScatterChart(
      ScatterChartData(
        minX: minXp,
        maxX: maxXp,
        minY: minYp,
        maxY: maxYp,
        gridData: FlGridData(
          show: !compact,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: (maxYp - minYp) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.08),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        scatterSpots: spots,
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (spot) => Colors.black.withValues(alpha: 0.9),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spot) {
              return ScatterTooltipItem(
                'X: ${spot.x.toInt()}\nY: ${spot.y.toStringAsFixed(1)}',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLineChartBase(
    List<LineChartBarData> bars,
    double minY,
    double maxY,
    bool compact,
  ) {
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: !compact,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.08),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                Colors.black.withValues(alpha: 0.9),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final driverIndex = touchedSpots.indexOf(spot);
                String driverCode = '';
                if (driverIndex < widget.enabledCodes.length) {
                  driverCode = widget.enabledCodes[driverIndex];
                }
                return LineTooltipItem(
                  '$driverCode\n${spot.y.toStringAsFixed(1)}',
                  TextStyle(
                    color: spot.bar.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        clipData: const FlClipData.none(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No data",
        style: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return <String, dynamic>{};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  Color _driverColor(dynamic payload, String code) {
    final drivers = payload.drivers;
    for (final d in drivers) {
      final m = d is Map<String, dynamic>
          ? d
          : Map<String, dynamic>.from(d as Map);
      if ((m["code"] ?? "") == code) {
        final hex = (m["color"] ?? "#90A4AE") as String;
        return _hexToColor(hex);
      }
    }
    return const Color(0xFF90A4AE);
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll("#", "");
    final v = int.tryParse("FF$h", radix: 16) ?? 0xFF90A4AE;
    return Color(v);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
