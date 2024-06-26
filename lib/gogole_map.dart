import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shop_app/featurs/main_page/featurs/profile/screen/shopping_address.dart';
import 'package:shop_app/injection.dart';
import 'package:toast/toast.dart';

import 'featurs/main_page/cubit/main_page_cubit.dart';
import 'featurs/main_page/data_source/data_source_paths.dart';
import 'featurs/main_page/featurs/check_out/cubit/check_out_cubit.dart';
import 'featurs/main_page/featurs/check_out/screens/add_another_address.dart';
import 'featurs/main_page/featurs/check_out/screens/first_step.dart';

class GoogleMapScreen extends StatefulWidget {
  final LatLng? currentLocation;
  final String fromPage;
  const GoogleMapScreen(
      {Key? key, this.currentLocation, required this.fromPage})
      : super(key: key);

  @override
  State<GoogleMapScreen> createState() => GoogleMapScreenState();
}

class GoogleMapScreenState extends State<GoogleMapScreen> {
  LocationPermission? permission;
  LatLng? centerLetLong;
  Position? currentLocation;
  LatLng? sourceLocation;
  bool isLoading = false;

  late GoogleMapController googleMapController;
//!mnb
  Future<void> getUserLocation() async {
    permission = await Geolocator.requestPermission();
    currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    centerLetLong =
        LatLng(currentLocation!.latitude, currentLocation!.longitude);
    sourceLocation = centerLetLong!;
    setState(() {});
    log('userCurentLocation $centerLetLong');
  }

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      "assets/images/location.png",
    ).then((icon) {
      sourceIcon = icon;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation == null) {
      getUserLocation();
    } else {
      sourceLocation = widget.currentLocation!;
    }
    setCustomMarkerIcon();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (value) async {
        context.read<MainPageCubit>().isAddLocationLoading = false;
        if (widget.fromPage == 'Orders') {
          context.read<CheckOutCubit>().getLocations().then((locations) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => FirstStep(
                      locations: locations,
                    )));
          });
        } else {
          List<Map<String, dynamic>> addressList =
              await sl.get<DataSource>().getLocations();
          if (context.mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => ShoppingAddress(addressList: addressList)));
          }
        }
      },
      child: Scaffold(
        body: Center(
          child: sourceLocation == null
              ? const CircularProgressIndicator(color: Colors.black)
              : Column(
                  children: [
                    SizedBox(
                      height: 792.h,
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          googleMapController = controller;
                        },
                        onTap: (argument) {
                          sourceLocation = argument;
                          setState(() {});
                        },
                        initialCameraPosition:
                            CameraPosition(target: sourceLocation!, zoom: 18.5),
                        mapType: MapType.normal,
                        markers: {
                          Marker(
                            icon: sourceIcon,
                            markerId: const MarkerId('source'),
                            position: sourceLocation!,
                          ),
                        },
                      ),
                    ),
                    BlocBuilder<MainPageCubit, MainPageState>(
                      builder: (context, state) {
                        isLoading =
                            context.read<MainPageCubit>().isAddLocationLoading;
                        return InkWell(
                          onTap: isLoading
                              ? null
                              : () async {
                                  context
                                      .read<MainPageCubit>()
                                      .changeIsAddLocationLoading(true);
                                  try {
                                    List<Placemark> placemarks =
                                        await placemarkFromCoordinates(
                                            sourceLocation!.latitude,
                                            sourceLocation!.longitude,
                                            localeIdentifier: 'en');
                                    log(placemarks.toString());
                                    Map<String, dynamic> data = {
                                      'sourceLocation': sourceLocation,
                                      'placeMark': placemarks[0]
                                    };
                                    if (context.mounted) {
                                      context
                                          .read<MainPageCubit>()
                                          .changeIsAddLocationLoading(false);
                                      Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  AddNewAddress(
                                                    checkOutCubit: context
                                                        .read<CheckOutCubit>(),
                                                    type: 'Add',
                                                    data: data,
                                                    fromPage: widget.fromPage,
                                                  )));
                                    }
                                  } catch (err) {
                                    if (context.mounted) {
                                      ToastContext().init(context);
                                      if (err.toString().contains(
                                          'No address information found for supplied coordinates')) {
                                        Toast.show(
                                            'You have to pick a valid location please try again',
                                            duration: Toast.lengthLong);
                                      } else if (err.toString().contains(
                                          'java.util.UnknownFormatConversionException')) {
                                        Toast.show(
                                            'You have to turn on VPN to add new location',
                                            duration: Toast.lengthLong);
                                      } else {
                                        Toast.show(
                                            'Unknown error please try again',
                                            duration: Toast.lengthLong);
                                      }
                                      context
                                          .read<MainPageCubit>()
                                          .changeIsAddLocationLoading(false);
                                    }
                                    log(err.toString());
                                  }
                                },
                          child: Ink(
                            height: 60.h,
                            width: 393.w,
                            decoration:
                                const BoxDecoration(color: Colors.black),
                            child: Center(
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Proceed',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w500),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
