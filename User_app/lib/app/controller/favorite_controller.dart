import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:app_user/app/backend/api/handler.dart';
import 'package:app_user/app/backend/models/banner_model.dart';
import 'package:app_user/app/backend/models/categories_model.dart';
import 'package:app_user/app/backend/models/individual_model.dart';
import 'package:app_user/app/backend/models/products_list_model.dart';
import 'package:app_user/app/backend/models/salon_model.dart';
import 'package:app_user/app/backend/parse/favorite_parse.dart';
import 'package:app_user/app/controller/all_categories_controller.dart';
import 'package:app_user/app/controller/categories_controller.dart';
import 'package:app_user/app/controller/categories_list_controller.dart';
import 'package:app_user/app/controller/checkout_controller.dart';
import 'package:app_user/app/controller/events_creation_controller.dart';
import 'package:app_user/app/controller/filter_controller.dart';
import 'package:app_user/app/controller/individual_checkout_controller.dart';
import 'package:app_user/app/controller/product_cart_controller.dart';
import 'package:app_user/app/controller/products_details_controller.dart';
import 'package:app_user/app/controller/search_controller.dart';
import 'package:app_user/app/controller/service_cart_controller.dart';
import 'package:app_user/app/controller/services_controller.dart';
import 'package:app_user/app/controller/specialist_controller.dart';
import 'package:app_user/app/controller/tabs_controller.dart';
import 'package:app_user/app/controller/top_offers_controller.dart';
import 'package:app_user/app/controller/top_packages_controller.dart';
import 'package:app_user/app/controller/top_products_controller.dart';
import 'package:app_user/app/controller/top_specialist_controller.dart';
import 'package:app_user/app/controller/video_controller.dart';
import 'package:app_user/app/helper/router.dart';
import 'package:app_user/app/util/constant.dart';
import 'package:app_user/app/util/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoriteController extends GetxController implements GetxService {
  final FavoritesParser parser;

  List<SalonModel> _salonList = <SalonModel>[];
  List<SalonModel> get salonList => _salonList;

  List<CategoriesModel> _categoriesList = <CategoriesModel>[];
  List<CategoriesModel> get categoriesList => _categoriesList;

  List<IndividualModel> _individualList = <IndividualModel>[];
  List<IndividualModel> get individualList => _individualList;

  List<BannerModel> _bannerList = <BannerModel>[];
  List<BannerModel> get bannerList => _bannerList;

  List<ProductsListModel> _productsList = <ProductsListModel>[];
  List<ProductsListModel> get productsList => _productsList;

  bool apiCalled = false;

  bool haveData = false;

  bool isIndividualInFavorites(int individualId) {
    return _individualList.any((individual) => individual.id == individualId);
  }

  bool isSalonInFavorites(int salonId) {
    return _salonList.any((salon) => salon.id == salonId);
  }

  String title = '';
  String currencySide = AppConstants.defaultCurrencySide;
  String currencySymbol = AppConstants.defaultCurrencySymbol;
  FavoriteController({required this.parser});

  @override
  void onInit() {
    super.onInit();
    currencySide = parser.getCurrencySide();
    currencySymbol = parser.getCurrencySymbol();
    title = parser.getAddressName();

    if (parser.isLogin() == true) {
      getFavoriteData();
    }
  }

  Future<void> getFavoriteData() async {
    var param = {"lat": parser.getLat(), "lng": parser.getLng()};
    Response response = await parser.getFavoritesData(param);
    apiCalled = true;

    if (response.statusCode == 200) {
      Map<String, dynamic> myMap = Map<String, dynamic>.from(response.body);
      var salonData = myMap['salon'];
      var categoriesData = myMap['categories'];
      var individualData = myMap['individual'];
      var bannerData = myMap['banners'];
      var products = myMap['products'];
      _salonList = [];
      _categoriesList = [];
      _individualList = [];
      _bannerList = [];
      _productsList = [];

      salonData.forEach((data) {
        SalonModel salon = SalonModel.fromJson(data);
        _salonList.add(salon);
      });
      debugPrint('Salon List Length: ${salonList.length}');

      categoriesData.forEach((data) {
        CategoriesModel categories = CategoriesModel.fromJson(data);
        _categoriesList.add(categories);
      });
      debugPrint('Categories List Length: ${categoriesList.length}');

      individualData.forEach((data) {
        IndividualModel individual = IndividualModel.fromJson(data);
        _individualList.add(individual);
      });
      debugPrint('Individual List Length: ${individualList.length}');

      bannerData.forEach((data) {
        BannerModel banner = BannerModel.fromJson(data);
        _bannerList.add(banner);
      });
      debugPrint('Banner List Length: ${bannerList.length}');

      products.forEach((data) {
        ProductsListModel product = ProductsListModel.fromJson(data);
        _productsList.add(product);
      });
      debugPrint('Products List Length: ${productsList.length}');

      checkCartData();
      if (_salonList.isEmpty && _individualList.isEmpty) {
        haveData = false;
      } else {
        haveData = true;
      }
      update();
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  void onServices(int id) {
    Get.delete<ServicesController>(force: true);
    Get.toNamed(AppRouter.getServicesRoutes(), arguments: [id]);
  }

  //TODO: Pass service and individual ids properly

  void onSpecialist(int id) {
    Get.delete<SpecialistController>(force: true);
    Get.delete<EventsCreationController>(force: true);
    Get.delete<VideoController>(force: true);
    Get.toNamed(AppRouter.getSpecialistRoutes(), arguments: [id, 0]);
  }

  void onAllCategories() {
    Get.delete<AllCategoriesController>(force: true);
    Get.toNamed(AppRouter.getAllCategoriesRoutes());
  }

  void onCategoriesList(int id) {
    Get.delete<CategoriesListController>(force: true);
    Get.toNamed(AppRouter.getCategoriesListRoutes(), arguments: [id]);
  }

  void onAllSpecialist() {
    Get.delete<TopSpecialistController>(force: true);
    Get.toNamed(AppRouter.getTopSpecialistRoutes());
  }

  void onAllOffers() {
    Get.delete<TopOffersController>(force: true);
    Get.toNamed(AppRouter.getTopOffersRoutes());
  }

  void onAllPackages() {
    Get.delete<TopPackagesController>(force: true);
    Get.toNamed(AppRouter.getTopPackagesRoutes());
  }

  void onTopProducts() {
    Get.delete<TopProductsControllrer>(force: true);
    Get.toNamed(AppRouter.getTopProductsRoutes());
  }

  void onSearch() {
    Get.delete<AppSearchController>(force: true);
    Get.toNamed(AppRouter.getSearchRoutes());
  }

  void onFilter() {
    Get.delete<FilterController>(force: true);
    Get.toNamed(AppRouter.getFilterRoutes());
  }

  void onProduct(int id) {
    Get.delete<ProductsDetailsController>(force: true);
    Get.toNamed(AppRouter.getProductsDetailsRoutes(), arguments: [id]);
  }

  void addToCart(int index) {
    if (Get.find<ProductCartController>().savedInCart.isEmpty) {
      _productsList[index].quantity = 1;
      Get.find<ProductCartController>().addItem(_productsList[index]);
      checkCartData();
      update();
    } else {
      int freelancerId = Get.find<ProductCartController>()
          .getFreelancerId(_productsList[index]);

      if (freelancerId == _productsList[index].freelacerId) {
        _productsList[index].quantity = 1;
        Get.find<ProductCartController>().addItem(_productsList[index]);
        checkCartData();
        update();
      } else {
        showToast('We already have product with other freelancer'.tr);
        update();
      }
    }
  }

  void updateProductQuantity(int index) {
    _productsList[index].quantity = _productsList[index].quantity + 1;
    Get.find<ProductCartController>().addQuantity(_productsList[index]);
    checkCartData();
    update();
  }

  void updateProductQuantityRemove(int index) {
    if (_productsList[index].quantity == 1) {
      _productsList[index].quantity = 0;
      Get.find<ProductCartController>().removeItem(_productsList[index]);
    } else {
      _productsList[index].quantity = _productsList[index].quantity - 1;
      Get.find<ProductCartController>().addQuantity(_productsList[index]);
    }
    checkCartData();
    update();
  }

  void checkCartData() {
    for (var element in _productsList) {
      if (Get.find<ProductCartController>()
              .checkProductInCart(element.id as int) ==
          true) {
        element.quantity =
            Get.find<ProductCartController>().getQuantity(element.id as int);
      } else {
        element.quantity = 0;
      }
    }
    Get.find<TabsController>().updateCartValue();
    update();
  }

  void onCheckout() {
    debugPrint('On Checkout');
    debugPrint(Get.find<ServiceCartController>().servicesFrom.toString());
    if (Get.find<ServiceCartController>().servicesFrom == 'individual') {
      Get.delete<IndividualCheckoutController>(force: true);
      Get.toNamed(AppRouter.getIndividualCheckout());
    } else {
      Get.delete<CheckoutController>(force: true);
      Get.toNamed(AppRouter.getCheckoutRoutes());
    }
  }

  void updateScreen() {
    update();
  }

  void onBanner(String value, String type) {
    debugPrint(value);
    debugPrint(type);
    if (type == '0') {
      debugPrint('category');
      Get.delete<CategoriesListController>(force: true);
      Get.toNamed(AppRouter.getCategoriesListRoutes(),
          arguments: [value, 'Offers']);
    } else if (type == '1') {
      debugPrint('individual');
      Get.delete<SpecialistController>(force: true);
      Get.delete<EventsCreationController>(force: true);
      Get.delete<VideoController>(force: true);
      Get.toNamed(AppRouter.getSpecialistRoutes(),
          arguments: [int.parse(value.toString()), 0]);
    } else if (type == '2') {
      debugPrint('salon');
      Get.delete<ServicesController>(force: true);
      Get.toNamed(AppRouter.getServicesRoutes(),
          arguments: [int.parse(value.toString())]);
    } else if (type == '3') {
      debugPrint('product category');
      Get.find<CategoriesController>().onCategoryExpand(value);
      Get.find<TabsController>().updateTabId(2);
    } else if (type == '4') {
      debugPrint('products');
      Get.delete<ProductsDetailsController>(force: true);
      Get.toNamed(AppRouter.getProductsDetailsRoutes(), arguments: [value]);
    } else if (type == '5') {
      debugPrint('external links');
      launchInBrowser(value);
    }
  }

  Future<void> launchInBrowser(String link) async {
    var url = Uri.parse(link);
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw '${'Could not launch'.tr} $url';
    }
  }
}
