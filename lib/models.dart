import 'package:hive/hive.dart';

class TradeEntry {
  final String id;
  final String date;
  final String platform;
  final String pairs;
  final String tradeType;
  final double pl;

  TradeEntry({
    required this.id,
    required this.date,
    required this.platform,
    required this.pairs,
    required this.tradeType,
    required this.pl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'platform': platform,
        'pairs': pairs,
        'tradeType': tradeType,
        'pl': pl,
      };

  factory TradeEntry.fromJson(Map<String, dynamic> json) => TradeEntry(
        id: json['id'],
        date: json['date'],
        platform: json['platform'],
        pairs: json['pairs'],
        tradeType: json['tradeType'],
        pl: (json['pl'] as num).toDouble(),
      );
}

class TradeEntryAdapter extends TypeAdapter<TradeEntry> {
  @override
  final int typeId = 0;

  @override
  TradeEntry read(BinaryReader reader) {
    return TradeEntry(
      id: reader.read(),
      date: reader.read(),
      platform: reader.read(),
      pairs: reader.read(),
      tradeType: reader.read(),
      pl: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, TradeEntry obj) {
    writer.write(obj.id);
    writer.write(obj.date);
    writer.write(obj.platform);
    writer.write(obj.pairs);
    writer.write(obj.tradeType);
    writer.write(obj.pl);
  }
}
