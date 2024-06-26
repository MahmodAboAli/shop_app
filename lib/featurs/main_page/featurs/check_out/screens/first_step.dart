import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/gogole_map.dart';
import 'package:shop_app/injection.dart';
import 'package:toast/toast.dart';

import '../../../data_source/data_source_paths.dart';
import '../cubit/check_out_cubit.dart';
import '../models/address_model.dart';
import '../widget/check_out_address.dart';
import '../widget/check_out_method.dart';
import '../widget/point.dart';
import 'second_step.dart';

class FirstStep extends StatelessWidget {
  final List<Map<String, dynamic>> locations;
  const FirstStep({super.key, required this.locations});

  @override
  Widget build(BuildContext context) {
    String? defaultLocation =
        sl.get<SharedPreferences>().getString('defaultLocation');
    context.read<CheckOutCubit>().selectAddress = defaultLocation ?? '';
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 60.h),
            child: Row(
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Image(
                      height: 40.w,
                      width: 40.w,
                      image: const AssetImage("assets/images/backicon.png"),
                    )),
                SizedBox(width: 10.w),
                Text(
                  "Check out",
                  style: TextStyle(fontSize: 18.sp, fontFamily: 'Tenor Sans'),
                )
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: EdgeInsets.only(left: 20.w, right: 20.w),
                child: Column(children: [
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      const Spacer(),
                      Image(
                          height: 25.h,
                          image:
                              const AssetImage('assets/images/location.png')),
                      SizedBox(width: 10.w),
                      const CheckOutPoint(),
                      const CheckOutPoint(),
                      const CheckOutPoint(),
                      const CheckOutPoint(),
                      const CheckOutPoint(),
                      SizedBox(width: 10.w),
                      Image(
                          height: 25.h,
                          image:
                              const AssetImage('assets/images/greycard.png')),
                      SizedBox(width: 10.w),
                      const CheckOutPoint(),
                      const CheckOutPoint(),
                      const CheckOutPoint(),
                      const CheckOutPoint(),
                      const CheckOutPoint(),
                      SizedBox(width: 10.w),
                      Image(
                          height: 25.h,
                          image: const AssetImage(
                              'assets/images/grey_check_out.png')),
                      const Spacer(),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 15.h),
                    width: double.infinity,
                    child: Text(
                      "Shopping Address",
                      style: TextStyle(
                          color: const Color(0xFF939393),
                          fontSize: 18.sp,
                          fontFamily: 'DM Sans'),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 15.h),
                    itemCount: locations.length,
                    itemBuilder: (BuildContext context, int index) {
                      AddressModel address =
                          AddressModel.fromMap(locations[index]);
                      return Dismissible(
                          background: Container(
                            padding: EdgeInsets.only(left: 19.65.w),
                            alignment: Alignment.centerLeft,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            // margin: EdgeInsets.only(left: 7.6335.w),
                            padding: EdgeInsets.only(right: 19.65.w),
                            alignment: Alignment.centerRight,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (value) async {
                            var res = await sl
                                .get<DataSource>()
                                .deleteAddress(address);
                            res.fold((add) {
                              context.read<CheckOutCubit>().changeAddress(add);
                            }, (r) {
                              ToastContext().init(context);
                              Toast.show(
                                  'Something went wrong please try again');
                            });
                          },
                          key: Key(address.addressName),
                          child: CheckOutAddressCard(
                              title: address.addressName,
                              description: address.address));
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const GoogleMapScreen(
                          fromPage: 'Orders',
                        ),
                      ));
                    },
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 15.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 15.h),
                      decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                                offset: const Offset(0, 11),
                                blurRadius: 11,
                                color: Colors.black.withOpacity(0.04))
                          ],
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        " +  Add Another Address",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
                    width: double.infinity,
                    child: Text(
                      "Shopping Method",
                      style: TextStyle(
                          color: const Color(0xFF939393),
                          fontSize: 18.sp,
                          fontFamily: 'DM Sans'),
                    ),
                  ),
                  const CheckOutMethodCard(
                      price: 'Free ',
                      title: "In store pick-up",
                      description: "Up until 30 days after placing order"),
                  SizedBox(height: 15.h),
                  const CheckOutMethodCard(
                      price: '\$4.99',
                      title: "Standard delivery",
                      description: "Delivery by Mon, April 5th"),
                  SizedBox(height: 15.h),
                  const CheckOutMethodCard(
                      price: '\$9.99',
                      title: "Express delivery",
                      description: "Same-day delivery"),
                  // Container(
                  //   margin: EdgeInsets.symmetric(vertical: 15.h),
                  //   width: double.infinity,
                  //   child: Text(
                  //     "Coupon Code",
                  //     style: TextStyle(
                  //         color: const Color(0xFF939393),
                  //         fontSize: 18.sp,
                  //         fontFamily: 'DM Sans'),
                  //   ),
                  // ),
                  // const CodeTextFeild(),
                  GestureDetector(
                    onTap: () {
                      if (locations.isNotEmpty) {
                        String latitude = '';
                        String longitude = '';
                        for (var element in locations) {
                          if (element['addressName'] ==
                              context.read<CheckOutCubit>().selectAddress) {
                            latitude = element['latitude_code'].toString();
                            longitude = element['longitude_code'].toString();
                          }
                        }
                        String selectedMethod =
                            context.read<CheckOutCubit>().selectMethod;
                        double deliveryCost =
                            selectedMethod == 'In store pick-up'
                                ? 0
                                : selectedMethod == 'Standard delivery'
                                    ? 4.99
                                    : 9.99;
                        deliveryCost += 10;
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => CheckOutScreen2(
                              latitude: latitude,
                              longitude: longitude,
                              deliveryCost: deliveryCost,
                              deliveryAddress:
                                  context.read<CheckOutCubit>().selectAddress),
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            shape: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10))),
                            backgroundColor: Colors.grey,
                            content: Center(
                              child: Text(
                                'You have to add address',
                                style: TextStyle(fontSize: 18.sp),
                              ),
                            )));
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 24.h),
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        "Continue to payment",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
