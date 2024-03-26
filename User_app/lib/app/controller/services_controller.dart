import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_user/app/backend/api/handler.dart';
import 'package:app_user/app/backend/models/categories_model.dart';
import 'package:app_user/app/backend/models/owner_reviews_model.dart';
import 'package:app_user/app/backend/models/packages_model.dart';
import 'package:app_user/app/backend/models/salon_details_model.dart';
import 'package:app_user/app/backend/models/specialist_model.dart';
import 'package:app_user/app/backend/parse/services_parse.dart';
import 'package:app_user/app/controller/chat_controller.dart';
import 'package:app_user/app/controller/checkout_controller.dart';
import 'package:app_user/app/controller/events_creation_controller.dart';
import 'package:app_user/app/controller/login_controller.dart';
import 'package:app_user/app/controller/packages_details_controller.dart';
import 'package:app_user/app/controller/selected_services_controller.dart';
import 'package:app_user/app/env.dart';
import 'package:app_user/app/helper/router.dart';
import 'package:app_user/app/helper/shared_pref.dart';
import 'package:app_user/app/util/constant.dart';
import 'package:app_user/app/util/toast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesController extends GetxController
    with GetTickerProviderStateMixin
    implements GetxService {
  final ServicesParser parser;
  late TabController tabController;
  final sharedPrefs = Get.find<SharedPreferencesManager>();

  int tabID = 1;

  String title = 'Select Service';

  List<String> dayList = [
    'Sunday'.tr,
    'Monday'.tr,
    'Tuesday'.tr,
    'Wednesday'.tr,
    'Thursday'.tr,
    'Friday'.tr,
    'Saturday'.tr
  ];

  List<String> gallery = [];

  SalonDetailsModel _salonDetails = SalonDetailsModel();
  SalonDetailsModel get salonDetails => _salonDetails;

  List<CategoriesModel> _categoriesList = <CategoriesModel>[];
  List<CategoriesModel> get categoriesList => _categoriesList;

  List<PackagesModel> _packagesList = <PackagesModel>[];
  List<PackagesModel> get packagesList => _packagesList;

  List<SpecialistModel> _specialistList = <SpecialistModel>[];
  List<SpecialistModel> get specialistList => _specialistList;

  List<OwnerReviewsModel> _ownerReviewsList = <OwnerReviewsModel>[];
  List<OwnerReviewsModel> get ownerReviewsList => _ownerReviewsList;

  String currencySide = AppConstants.defaultCurrencySide;
  String currencySymbol = AppConstants.defaultCurrencySymbol;

  String selectedService = '';
  String selectedServiceName = '';

  bool apiCalled = false;
  bool reviewsCalled = false;

  int? salonId = 0;
  final Set<Marker> markers = {};
  String getDistance = '';
  List<String> brandSizeList = [];
  ServicesController({required this.parser});

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      debugPrint(tabController.index.toString());
      if (tabController.index == 3) {
        reviewsCalled = false;
        update();
        getOwnerReviews();
      }
    });
    if (Get.arguments == null) {
      salonId = sharedPrefs.getInt("key-salonId") ?? null;
    } else {
      salonId = Get.arguments[0];
    }
    getSalonDetails();
    currencySide = parser.getCurrencySide();
    currencySymbol = parser.getCurrencySymbol();
  }

  Future<void> getSalonDetails() async {
    if (salonId == null) {
      return;
    }
    var response = await parser.salonDetails({"id": salonId});
    if (response.statusCode == 200) {
      print('API Response: ${response.body}');
      apiCalled = true;
      Map<String, dynamic> myMap = Map<String, dynamic>.from(response.body);
      var body = myMap['data'];
      var salonCategories = myMap['categories'];
      var salonPackages = myMap['packages'];
      var salonSpecialist = myMap['specialist'];

      _salonDetails = SalonDetailsModel();
      _categoriesList = [];
      _packagesList = [];
      _specialistList = [];

      SalonDetailsModel services = SalonDetailsModel.fromJson(body);
      _salonDetails = services;
      if (salonDetails.images != 'NA' &&
          salonDetails.images != null &&
          salonDetails.images != '') {
        var imgs = jsonDecode(salonDetails.images!);
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
      if (salonDetails.inHome == 1) {
        brandSizeList.add("solo");
      }
      if (salonDetails.haveStylist == 1) {
        brandSizeList.add("duo");
      }
      if (salonDetails.serviceAtHome == 1) {
        brandSizeList.add("trio");
      }
      salonCategories.forEach((data) {
        CategoriesModel categories = CategoriesModel.fromJson(data);
        _categoriesList.add(categories);
      });
      debugPrint(' LIst: ${categoriesList.length.toString()}');

      salonPackages.forEach((data) {
        PackagesModel packages = PackagesModel.fromJson(data);
        _packagesList.add(packages);
      });
      debugPrint(packagesList.length.toString());

      salonSpecialist.forEach((data) {
        SpecialistModel specialist = SpecialistModel.fromJson(data);
        _specialistList.add(specialist);
      });
      debugPrint(specialistList.length.toString());
      double storeDistance = 0.0;
      double totalMeters = 0.0;
      storeDistance = Geolocator.distanceBetween(
        double.tryParse(_salonDetails.lat.toString()) ?? 0.0,
        double.tryParse(_salonDetails.lng.toString()) ?? 0.0,
        double.tryParse(parser.getLat().toString()) ?? 0.0,
        double.tryParse(parser.getLng().toString()) ?? 0.0,
      );
      totalMeters = totalMeters + storeDistance;
      double distance = double.parse((storeDistance / 1000).toStringAsFixed(2));
      debugPrint(distance.toString());
      getDistance = distance.toString();
      update();
    } else {
      Get.back();
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> getOwnerReviews() async {
    var response = await parser.getOwnerReviewsList({"id": salonId});
    reviewsCalled = true;
    _ownerReviewsList = [];
    update();
    if (response.statusCode == 200) {
      Map<String, dynamic> myMap = Map<String, dynamic>.from(response.body);
      var body = myMap['data'];

      body.forEach((data) {
        OwnerReviewsModel reviews = OwnerReviewsModel.fromJson(data);
        _ownerReviewsList.add(reviews);
      });
      update();
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  onMapCreated() {
    markers.add(
      Marker(
        markerId: const MarkerId('Id-1'),
        position:
            LatLng(salonDetails.lat as double, salonDetails.lng as double),
      ),
    );
  }

  // void onBookAppointment() {
  //   Get.delete<BookAppointmentController>(force: true);
  //   Get.toNamed(AppRouter.getBookAppointmentRoutes());
  // }

  void onServicesView(int id, String name) {
    Get.delete<SelectedServicesController>(force: true);
    Get.toNamed(AppRouter.getSelectedServicesRoutes(),
        arguments: [id, name, salonDetails.uid]);
  }

  void onPackagesDetails(int id, String name) {
    Get.delete<PackagesDetailsController>(force: true);
    Get.toNamed(AppRouter.getPackagesDetailsRoutes(), arguments: [id, name]);
  }

  Future<void> openWebsite() async {
    if (salonDetails.website.toString() != 'NA' ||
        salonDetails.website!.isEmpty ||
        salonDetails.website != null) {
      var url = Uri.parse(salonDetails.website.toString());
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw 'Could not launch $url';
      }
    } else {
      showToast('No Website Found'.tr);
    }
  }

  Future<void> callSalon() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: salonDetails.mobile.toString(),
    );
    await launchUrl(launchUri);
  }

  Future<void> openMap() async {
    double latitude = salonDetails.lat as double;
    double longitude = salonDetails.lng as double;
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    var url = Uri.parse(googleUrl);
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
  }

  Future<void> share() async {
    await FlutterShare.share(
        title: Environments.appName,
        text: '${'Please checkout this salon'.tr} ${salonDetails.name}',
        linkUrl: salonDetails.website.toString(),
        chooserTitle: 'Share with'.tr);
  }

  void onChat() {
    debugPrint('on chat');
    if (parser.isLogin() == true) {
      Get.delete<ChatController>(force: true);
      Get.toNamed(AppRouter.getChatRoutes(), arguments: [
        salonDetails.uid.toString(),
        salonDetails.name.toString()
      ]);
    } else {
      Get.delete<LoginController>(force: true);
      Get.toNamed(AppRouter.getLoginRoute());
    }
  }

  void onCheckout() {
    Get.delete<CheckoutController>(force: true);
    Get.toNamed(AppRouter.getCheckoutRoutes());
  }

  void onBack() {
    var context = Get.context as BuildContext;
    Navigator.of(context).pop(true);
  }

  void updateScreen() {
    update();
  }

  Future<void> updateFavoriteSalon(int isFavorite) async {
    apiCalled = false;
    update();
    var response = await parser
        .updateFavoriteSalon({"id": salonId, "is_favorite": isFavorite});
    if (response.statusCode == 200) {
      var res = getSalonDetails();
      _salonDetails.isFavorite = 1;
    } else {
      ApiChecker.checkApi(response);
    }
    successToast("Artist added to favorites");
    apiCalled = true;
    update();
  }

  Future<void> deleteFromFavorites() async {
    apiCalled = false;
    update();

    try {
      var response =
          await parser.deleteFavoriteSalon({"id": salonId, "is_favorite": 0});
      if (response.statusCode == 200) {
        // Assuming 0 represents not in favorites
        var res = getSalonDetails();
        _salonDetails.isFavorite = 0;
      } else {
        ApiChecker.checkApi(response);
      }
    } catch (e) {
      // Handle exceptions or errors here
      print('Error: $e');
    }

    successToast("Artist removed from favorites");
    apiCalled = true;
    update();
  }

  void onToSendContract(bool isSpecialist) {
    if (parser.isLogin() == true) {
      Get.delete<EventsCreationController>(force: true);
      Get.toNamed(
        AppRouter.eventsCreationRoutes,
        arguments: [
          null,
          salonId,
          brandSizeList,
           isSpecialist,
        ],
      );
    } else {
      showToast('Please login now'.tr);
    }
  }
}
