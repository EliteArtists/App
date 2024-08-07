class ProfileModel {
  int? id;
  int? uid;
  String? name;
  String? cover;
  String? categories;
  String? address;
  String? lat;
  String? lng;
  int? cid;
  String? about;
  double? rating;
  int? totalRating;
  String? website;
  String? timing;
  String? images;
  String? zipcode;
  String? selectedAcusticSoloValue;
  String? selectedAcusticDuoValue;
  String? selectedAcusticTrioValue;
  String? selectedAcusticQuarterValue;
  String? weddingEditor;
  String? travelEditor; 
  int? serviceAtHome;
  int? verified;
  int? inHome;
  int? popular;
  int? haveShop;
  int? haveStylist;
  String? extraField;
  int? status;
  List<WebCatesData>? webCatesData;
  CityData? cityData;
  String? selectedAcusticSoloValueInstrument;
  String? selectedAcusticDuoValueInstrument;
  String? selectedAcusticTrioValueInstrument;
  String? selectedAcusticQuarterValueInstrument;
  String? weddingEditorInstrument;
  String? contactName;
  String? contactNumber;

  ProfileModel(
      {this.id,
      this.uid,
      this.name,
      this.cover,
      this.categories,
      this.address,
      this.lat,
      this.lng,
      this.cid,
      this.about,
      this.rating,
      this.totalRating,
      this.website,
      this.timing,
      this.images,
      this.zipcode,
      this.serviceAtHome,
      this.verified,
      this.inHome,
      this.popular,
      this.haveShop,
      this.haveStylist,
      this.extraField,
      this.status,
      this.webCatesData,
      this.cityData,
      this.selectedAcusticSoloValue,
      this.selectedAcusticDuoValue,
      this.selectedAcusticQuarterValue,
      this.selectedAcusticTrioValue,
      this.travelEditor,
      this.weddingEditor,
      this.selectedAcusticDuoValueInstrument,
      this.selectedAcusticQuarterValueInstrument,
      this.selectedAcusticSoloValueInstrument,
      this.selectedAcusticTrioValueInstrument,
      this.weddingEditorInstrument, 
      this.contactName,
      this.contactNumber});

  ProfileModel.fromJson(Map<String, dynamic> json) {
    id = int.parse(json['id'].toString());
    uid = int.parse(json['uid'].toString());
    name = json['name'];
    cover = json['cover'];
    categories = json['categories'];
    address = json['address'];
    lat = json['lat'];
    lng = json['lng'];
    cid = int.parse(json['cid'].toString());
    about = json['about'];
    rating = double.parse(json['rating'].toString());
    totalRating = int.parse(json['total_rating'].toString());
    website = json['website'];
    timing = json['timing'];
    images = json['images'];
    zipcode = json['zipcode'];
    selectedAcusticSoloValue = json['acustic_solo'];
    selectedAcusticDuoValue = json['acustic_duo'];
    selectedAcusticQuarterValue = json['setup'];
    selectedAcusticTrioValue = json['acustic_trio'];
    travelEditor = json['travel'];
    weddingEditor = json['wedding'];
    serviceAtHome = int.parse(json['service_at_home'].toString());
    verified = int.parse(json['verified'].toString());
    inHome = int.parse(json['in_home'].toString());
    popular = int.parse(json['popular'].toString());
    haveShop = int.parse(json['have_shop'].toString());
    haveStylist = int.parse(json['have_stylist'].toString());
    selectedAcusticDuoValueInstrument = json['acustic_duoinstru'];
    selectedAcusticQuarterValueInstrument = json['acustic_quarterinstru'];
    selectedAcusticTrioValueInstrument = json['acustic_trioinstru'];
    selectedAcusticSoloValueInstrument = json['acustic_soloinstru'];
    weddingEditorInstrument = json['acustic_weddinginstru'];
    contactName = json['contact_name'];
    contactNumber = json['contact_number'];
    extraField = json['extra_field'];
    status = int.parse(json['status'].toString());
    if (json['web_cates_data'] != null) {
      webCatesData = <WebCatesData>[];
      json['web_cates_data'].forEach((v) {
        webCatesData!.add(WebCatesData.fromJson(v));
      });
    }
    cityData =
        json['city_data'] != null ? CityData.fromJson(json['city_data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['name'] = name;
    data['cover'] = cover;
    data['categories'] = categories;
    data['address'] = address;
    data['lat'] = lat;
    data['lng'] = lng;
    data['cid'] = cid;
    data['about'] = about;
    data['rating'] = rating;
    data['total_rating'] = totalRating;
    data['website'] = website;
    data['timing'] = timing;
    data['images'] = images;
    data['zipcode'] = zipcode;
    data['service_at_home'] = serviceAtHome;
    data['verified'] = verified;
    data['in_home'] = inHome;
    data['popular'] = popular;
    data['have_shop'] = haveShop;
    data['have_stylist'] = haveStylist;
    data['extra_field'] = extraField;
    data['acustic_solo'] = selectedAcusticSoloValue;
    data['acustic_duo'] = selectedAcusticDuoValue;
    data['setup'] = selectedAcusticQuarterValue;
    data['acustic_trio'] = selectedAcusticTrioValue;
    data['travel'] = travelEditor;
    data['wedding']= weddingEditor;
    data['status'] = status;
    data['acustic_duoinstru'] = selectedAcusticDuoValueInstrument;
    data['acustic_quarterinstru'] = selectedAcusticQuarterValueInstrument;
    data['acustic_trioinstru'] = selectedAcusticTrioValueInstrument;
    data['acustic_soloinstru'] = selectedAcusticSoloValueInstrument;
    data['acustic_weddinginstru'] = weddingEditorInstrument;
    data['contact_name'] = contactName;
    data['contact_number'] = contactNumber;
    if (webCatesData != null) {
      data['web_cates_data'] = webCatesData!.map((v) => v.toJson()).toList();
    }
    if (cityData != null) {
      data['city_data'] = cityData!.toJson();
    }
    return data;
  }
}

class WebCatesData {
  int? id;
  String? name;
  String? cover;
  String? extraField;
  int? status;

  WebCatesData({this.id, this.name, this.cover, this.extraField, this.status});

  WebCatesData.fromJson(Map<String, dynamic> json) {
    id = int.parse(json['id'].toString());
    name = json['name'];
    cover = json['cover'];
    extraField = json['extra_field'];
    status = int.parse(json['status'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['cover'] = cover;
    data['extra_field'] = extraField;
    data['status'] = status;
    return data;
  }
}

class CityData {
  int? id;
  String? name;
  String? lat;
  String? lng;
  String? extraField;
  int? status;

  CityData(
      {this.id, this.name, this.lat, this.lng, this.extraField, this.status});

  CityData.fromJson(Map<String, dynamic> json) {
    id = int.parse(json['id'].toString());
    name = json['name'];
    lat = json['lat'];
    lng = json['lng'];
    extraField = json['extra_field'];
    status = int.parse(json['status'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['lat'] = lat;
    data['lng'] = lng;
    data['extra_field'] = extraField;
    data['status'] = status;
    return data;
  }
}
