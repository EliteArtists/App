import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:app_user/app/backend/api/handler.dart';
import 'package:app_user/app/backend/models/packages_details_model.dart';
import 'package:app_user/app/backend/parse/individual_packages_parse.dart';
import 'package:app_user/app/controller/home_controller.dart';
import 'package:app_user/app/controller/individual_checkout_controller.dart';
import 'package:app_user/app/controller/service_cart_controller.dart';
import 'package:app_user/app/helper/router.dart';
import 'package:app_user/app/util/constant.dart';
import 'package:app_user/app/util/toast.dart';

class IndividualPackagesController extends GetxController
    implements GetxService {
  final IndividualPackagesParser parser;
  int packagesDetailsId = 0;

  bool apiCalled = false;

  List<String> gallery = [];

  List<int> packages = [];

  PackagesDetailsModel _packagesDetails = PackagesDetailsModel();
  PackagesDetailsModel get packagesDetails => _packagesDetails;

  String currencySide = AppConstants.defaultCurrencySide;
  String currencySymbol = AppConstants.defaultCurrencySymbol;

  IndividualPackagesController({required this.parser});

  @override
  void onInit() {
    super.onInit();
    packagesDetailsId = Get.arguments[0];
    debugPrint('packagesId --> $packagesDetailsId');
    getSalonDetails();
    currencySide = parser.getCurrencySide();
    currencySymbol = parser.getCurrencySymbol();
  }

  Future<void> getSalonDetails() async {
    var response = await parser.getPackagesById({"id": packagesDetailsId});
    apiCalled = true;
    if (response.statusCode == 200) {
      Map<String, dynamic> myMap = Map<String, dynamic>.from(response.body);
      var body = myMap['data'];

      _packagesDetails = PackagesDetailsModel();

      PackagesDetailsModel packages = PackagesDetailsModel.fromJson(body);
      if (Get.find<ServiceCartController>()
          .checkPackageInCart(packages.id as int)) {
        packages.isBooked = true;
      } else {
        packages.isBooked = false;
      }

      _packagesDetails = packages;

      if (packagesDetails.images != 'NA' &&
          packagesDetails.images != null &&
          packagesDetails.images != '') {
        var imgs = jsonDecode(packagesDetails.images!);
        gallery = [];
        if (imgs.length > 0) {
          imgs.forEach((element) {
            if (element != '') {
              gallery.add(element);
            }
          });
          update();
        }
      }
    } else {
      ApiChecker.checkApi(response);
    }

    update();
  }

  void addPackageToCart() {
    if (Get.find<ServiceCartController>().savedInCart.packages!.isEmpty &&
        Get.find<ServiceCartController>().savedInCart.services!.isEmpty) {
      _packagesDetails.isBooked = true;
      Get.find<ServiceCartController>()
          .addPackageToCart(_packagesDetails, 'salon');
      update();
    } else if (Get.find<ServiceCartController>()
        .savedInCart
        .services!
        .isNotEmpty) {
      int freenlancerServiceId =
          Get.find<ServiceCartController>().getServiceFreelancerId();
      if (freenlancerServiceId == _packagesDetails.uid) {
        _packagesDetails.isBooked = true;
        Get.find<ServiceCartController>()
            .addPackageToCart(_packagesDetails, 'individual');
        update();
      } else {
        showToast(
            'We already have service or package with other salon or with freelancer'
                .tr);
      }
    } else {
      int freelancerId =
          Get.find<ServiceCartController>().getPackageFreelancerId();

      if (freelancerId == _packagesDetails.uid) {
        _packagesDetails.isBooked = true;
        Get.find<ServiceCartController>()
            .addPackageToCart(_packagesDetails, 'individual');
        update();
      } else {
        showToast(
            'We already have service or package with other salon or with freelancer'
                .tr);
        update();
      }
    }
    Get.find<HomeController>().updateScreen();
  }

  void removePackageFromCart() {
    _packagesDetails.isBooked = false;
    Get.find<ServiceCartController>()
        .removePackageFromCart(_packagesDetails.id as int);
    Get.find<HomeController>().updateScreen();
    update();
  }

  void onCheckout() {
    Get.delete<IndividualCheckoutController>(force: true);
    Get.toNamed(AppRouter.getIndividualCheckout());
  }
}
