import 'package:flutter/material.dart';
import '../storage.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final table = StorageService.getCalculatedTable();
    double totalPl = 0;
    int winCount = 0;
    int lossCount = 0;
    double totalWin = 0;
    double totalLoss = 0;
    double bestDay = 0;
    double worstDay = 0;
    
    double currentWinStreak = 0;
    double currentLossStreak = 0;
    double maxWinStreak = 0;
    double maxLossStreak = 0;
    
    double peakBalance = StorageService.initialBalance ?? 0;
    double maxDrawdown = 0;
    double maxRunUp = 0;
    
    Map<String, int> platTotal = {};
    Map<String, int> platWins = {};
    
    List<FlSpot> spots = [];
    if (table.isNotEmpty) {
      spots.add(FlSpot(0, StorageService.initialBalance ?? 0));
    }

    double cumulativePl = 0;
    for (var row in table) {
      final e = row['entry'];
      final bal = row['balance'];
      totalPl += e.pl;
      cumulativePl += e.pl;
      
      if (cumulativePl > maxRunUp) maxRunUp = cumulativePl;
      
      platTotal[e.platform] = (platTotal[e.platform] ?? 0) + 1;
      if (e.pl > 0) platWins[e.platform] = (platWins[e.platform] ?? 0) + 1;
      
      if (e.pl > 0) {
        winCount++;
        totalWin += e.pl;
        if (e.pl > bestDay) bestDay = e.pl;
        currentWinStreak++;
        currentLossStreak = 0;
        if (currentWinStreak > maxWinStreak) maxWinStreak = currentWinStreak;
      } else if (e.pl < 0) {
        lossCount++;
        totalLoss += e.pl.abs();
        if (e.pl < worstDay) worstDay = e.pl;
        currentLossStreak++;
        currentWinStreak = 0;
        if (currentLossStreak > maxLossStreak) maxLossStreak = currentLossStreak;
      } else {
        currentWinStreak = 0;
        currentLossStreak = 0;
      }
      
      if (bal > peakBalance) peakBalance = bal;
      double dd = bal - peakBalance;
      if (dd < maxDrawdown) maxDrawdown = dd;
      
      spots.add(FlSpot(row['dayNum'].toDouble(), bal));
    }
    
    int totalTrades = table.length;
    double winRate = totalTrades == 0 ? 0 : (winCount / totalTrades) * 100;
    double avgWin = winCount == 0 ? 0 : totalWin / winCount;
    double avgLoss = lossCount == 0 ? 0 : totalLoss / lossCount;
    double rrRatio = avgLoss == 0 ? 0 : avgWin / avgLoss;

    List<BarChartGroupData> barGroups = [];
    List<String> platNames = [];
    int platIndex = 0;
    platTotal.forEach((plat, total) {
      double wr = total > 0 ? (platWins[plat] ?? 0) / total * 100 : 0;
      barGroups.add(BarChartGroupData(
        x: platIndex,
        barRods: [BarChartRodData(toY: wr, color: const Color(0xFF10B981), width: 14, borderRadius: BorderRadius.circular(2))],
      ));
      platNames.add(plat);
      platIndex++;
    });

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _statCard('Total P/L', '\$${totalPl.toStringAsFixed(2)}', color: totalPl >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
          _statCard('Total Trades', '$totalTrades'),
          Row(
            children: [
              Expanded(child: _statCard('Wins', '$winCount', color: const Color(0xFF10B981))),
              Expanded(child: _statCard('Losses', '$lossCount', color: const Color(0xFFF43F5E))),
            ],
          ),
          _statCard('Win Rate', '${winRate.toStringAsFixed(1)}%'),
          _statCard('Avg Win', '\$${avgWin.toStringAsFixed(2)}'),
          _statCard('Avg Loss', '\$${avgLoss.toStringAsFixed(2)}'),
          Container(
             margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: const Color(0x330EA5E9), border: Border.all(color: const Color(0x4D0EA5E9)), borderRadius: BorderRadius.circular(6)),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  const Text('RISK-REWARD RATIO', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Text(rrRatio.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
               ]
             )
          ),
          _statCard('Best Day', '\$${bestDay.toStringAsFixed(2)}', color: const Color(0xFF10B981)),
          _statCard('Worst Day', '\$${worstDay.toStringAsFixed(2)}', color: const Color(0xFFF43F5E)),
          const Divider(height: 30, color: Color(0xFF1E293B)),
          const Text('Risk Metrics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE2E8F0))),
          const SizedBox(height: 8),
          Row(
            children: [
               Expanded(child: _statCard('Max Drawdown', '\$${maxDrawdown.toStringAsFixed(2)}', color: const Color(0xFFF43F5E))),
               Expanded(child: _statCard('Max Run-up', '\$${maxRunUp.toStringAsFixed(2)}', color: const Color(0xFF10B981))),
            ],
          ),
          const Divider(height: 30, color: Color(0xFF1E293B)),
          const Text('Streaks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE2E8F0))),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _statCard('Cur. Win', '${currentWinStreak.toInt()}')),
              Expanded(child: _statCard('Cur. Loss', '${currentLossStreak.toInt()}')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _statCard('Max Win', '${maxWinStreak.toInt()}')),
              Expanded(child: _statCard('Max Loss', '${maxLossStreak.toInt()}')),
            ],
          ),
          const Divider(height: 30, color: Color(0xFF1E293B)),
          const Text('Equity Curve', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE2E8F0))),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), border: Border.all(color: const Color(0xFF1E293B)), borderRadius: BorderRadius.circular(8)),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFF1E293B), strokeWidth: 1), getDrawingVerticalLine: (value) => FlLine(color: const Color(0xFF1E293B), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)))),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0), style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace')))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xFF1E293B))),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF0EA5E9),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: const Color(0x330EA5E9)),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 30, color: Color(0xFF1E293B)),
          const Text('Win Rate by Platform (%)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE2E8F0))),
          const SizedBox(height: 16),
          if (barGroups.isNotEmpty) Container(
            height: 250,
            padding: const EdgeInsets.only(top: 16, right: 16, left: 0, bottom: 16),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), border: Border.all(color: const Color(0xFF1E293B)), borderRadius: BorderRadius.circular(8)),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFF1E293B), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) {
                    if (v.toInt() >= 0 && v.toInt() < platNames.length) {
                      return Padding(padding: const EdgeInsets.only(top: 8), child: Text(platNames[v.toInt()], style: const TextStyle(color: Color(0xFF64748B), fontSize: 9), overflow: TextOverflow.ellipsis));
                    }
                    return const Text('');
                  })),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0)+'%', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace')))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, {Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color ?? const Color(0xFFE2E8F0), fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
