import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:app_user/app/backend/api/handler.dart';
import 'package:app_user/app/backend/models/top_salon_model.dart';
import 'package:app_user/app/backend/parse/top_offers_parse.dart';
import 'package:app_user/app/controller/services_controller.dart';
import 'package:app_user/app/helper/router.dart';

class TopOffersController extends GetxController implements GetxService {
  final TopOffersParser parser;

  List<TopSalonModel> _topSalonList = <TopSalonModel>[];
  List<TopSalonModel> get topSalonList => _topSalonList;

  String topSalonId = '';
  String topSalonName = '';

  bool apiCalled = false;

  TopOffersController({required this.parser});

  @override
  void onInit() {
    super.onInit();
    getTopSalon();
  }

  Future<void> getTopSalon() async {
    var param = {"lat": parser.getLat(), "lng": parser.getLng()};
    Response response = await parser.getTopSalon(param);
    apiCalled = true;

    if (response.statusCode == 200) {
      Map<String, dynamic> myMap = Map<String, dynamic>.from(response.body);
      var topSalonData = myMap['data'];

      _topSalonList = [];

      topSalonData.forEach((data) {
        TopSalonModel datas = TopSalonModel.fromJson(data);
        _topSalonList.add(datas);
      });
      debugPrint(topSalonList.length.toString());
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  void onServices(int id) {
    Get.delete<ServicesController>(force: true);
    Get.toNamed(AppRouter.getServicesRoutes(), arguments: [id]);
  }
}
