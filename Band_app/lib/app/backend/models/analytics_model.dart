import 'package:jiffy/jiffy.dart';

class AnalyticsModel {
  int? count;
  String? dayName;
  String? day;
  double? total;

  AnalyticsModel({this.count, this.dayName, this.day, this.total});

  AnalyticsModel.fromJson(Map<String, dynamic> json) {
    count = int.parse(json['count'].toString());
    dayName = Jiffy(json['day_name'].toString()).format('EEEE, dd');
    day = Jiffy(json['day'].toString()).yMMMMd;
    total = double.parse(json['total'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['count'] = count;
    data['day_name'] = dayName;
    data['day'] = day;
    data['total'] = total;
    return data;
  }
}
