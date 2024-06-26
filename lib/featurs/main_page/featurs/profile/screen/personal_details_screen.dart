import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/featurs/main_page/main_page.dart';
import 'package:toast/toast.dart';
import 'package:uuid/v1.dart';

import '../../../../../core/constant.dart';
import '../../../../../core/internet_info.dart';
import '../../../../../injection.dart';
import '../../../../auth/models/user_model.dart';
import '../../../data_source/data_source.dart';
import '../cubit/profile_cubit.dart';

class PersonalDetails extends StatefulWidget {
  final ProfileCubit profileCubit;
  final PageController pageController;
  final TabController tabController;
  const PersonalDetails(
      {super.key,
      required this.profileCubit,
      required this.pageController,
      required this.tabController});

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails>
    with SingleTickerProviderStateMixin {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  late GlobalKey<FormState> formKey;

  String? imgUrl;
  @override
  void initState() {
    fullNameController.text = Constant.currentUser!.name;
    phoneNumberController.text = Constant.currentUser!.phoneNumber ?? '';
    emailController.text = Constant.currentUser!.email;
    formKey = GlobalKey<FormState>();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    context.read<ProfileCubit>().changeIsSaveButtonLoading(false);
    return PopScope(
      canPop: false,
      onPopInvoked: (value) {
        goToHomePage(context);
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 60.h),
            child: Column(children: [
              Row(
                children: [
                  GestureDetector(
                      onTap: () {
                        goToHomePage(context);
                      },
                      child: Image(
                        height: 40.w,
                        width: 40.w,
                        image: const AssetImage("assets/images/backicon.png"),
                      )),
                  SizedBox(width: 8.w),
                  Text(
                    "Personal Details",
                    style: TextStyle(fontSize: 18.sp, fontFamily: 'Tenor Sans'),
                  )
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  const Spacer(),
                  Stack(
                    alignment: const Alignment(1.2, 1.2),
                    children: [
                      BlocBuilder<ProfileCubit, ProfileState>(
                        builder: (context, state) {
                          return Container(
                              height: 130.h,
                              width: 130.w,
                              decoration: BoxDecoration(
                                  image: Constant.currentUser!.imgUrl != null
                                      ? DecorationImage(
                                          fit: BoxFit.cover,
                                          image: ResizeImage(
                                              height: 130.h.toInt(),
                                              width: 130.w.toInt(),
                                              FileImage(File(Constant
                                                  .currentUser!.imgUrl!))))
                                      : null,
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Constant.currentUser!.imgUrl == null
                                  ? SizedBox(
                                      height: 130,
                                      width: 130,
                                      child: Center(
                                        child: Text(
                                          Constant.getLetterName(
                                              Constant.currentUser!.name),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 3,
                                              fontSize: 40.sp,
                                              color: Colors.white),
                                        ),
                                      ),
                                    )
                                  : null);
                        },
                      ),
                      GestureDetector(
                        onTap: () async {
                          ImagePicker imagePicker = ImagePicker();
                          XFile? file = await imagePicker.pickImage(
                              source: ImageSource.gallery);
                          if (file != null) {
                            try {
                              if (Constant.currentUser!.imgUrl != null) {
                                await File(Constant.currentUser!.imgUrl!)
                                    .delete();
                              }
                              String fileName = UuidV1().toString();
                              await File(file.path)
                                  .copy('${Constant.baseUrl + fileName}.jpg');
                              Constant.currentUser!.imgUrl =
                                  '${Constant.baseUrl + fileName}.jpg';
                              await sl.get<SharedPreferences>().setString(
                                  'currentUser',
                                  Constant.currentUser!.toJson());
                              imgUrl = '${Constant.baseUrl + fileName}.jpg';
                              if (context.mounted) {
                                context
                                    .read<ProfileCubit>()
                                    .changeProfileImagePath(imgUrl!);
                              }
                            } catch (e) {
                              log(e.toString());
                            }
                          } else {
                            log('empty image');
                          }
                        },
                        child: Container(
                          height: 40.h,
                          width: 40.h,
                          padding: EdgeInsets.only(top: 8.h),
                          decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 4),
                                  color: Colors.black.withOpacity(.25),
                                  blurRadius: 4,
                                )
                              ],
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Image(
                              image: AssetImage("assets/images/Pen.png")),
                        ),
                      )
                    ],
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(height: 80.h),
              Row(
                children: [
                  Expanded(
                      child: Text(
                    "Full Name",
                    style: TextStyle(
                        color: Color(0xFFA5A5A5), fontFamily: 'DM Sans'),
                  )),
                ],
              ),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    SizedBox(
                        width: 393.w,
                        height: 50.h,
                        child: TextFormField(
                          validator: (value) {
                            if (value != null && value.length <= 3) {
                              return 'Full name should be more than three litters';
                            }
                            return null;
                          },
                          maxLength: 50,
                          cursorColor: Colors.black,
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          controller: fullNameController,
                        )),
                    SizedBox(height: 24.h),
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        "Email",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            color: Color(0xFFA5A5A5), fontFamily: 'DM Sans'),
                      ),
                    ),
                    TextField(
                      readOnly: true,
                      maxLength: 50,
                      cursorColor: Colors.black,
                      onTapOutside: (value) {
                        FocusScope.of(context).unfocus();
                      },
                      controller: emailController,
                    ),
                    SizedBox(height: 25.h),
                    const Row(
                      children: [
                        Expanded(
                            child: Text(
                          "Phone Number",
                          style: TextStyle(
                              color: Color(0xFFA5A5A5), fontFamily: 'DM Sans'),
                        )),
                      ],
                    ),
                    SizedBox(
                        height: 70.h,
                        width: 393.w,
                        child: TextFormField(
                          validator: (value) {
                            log(value.toString());
                            if (value != null &&
                                value != '' &&
                                (value.length <= 9 || !value.startsWith('+'))) {
                              return 'invalid phone number';
                            }
                            return null;
                          },
                          maxLength: 50,
                          cursorColor: Colors.black,
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              hintStyle: const TextStyle(color: Colors.grey),
                              hintText: phoneNumberController.text == ''
                                  ? 'No Phone number'
                                  : ''),
                          controller: phoneNumberController,
                        )),
                  ],
                ),
              ),
              Row(children: [
                const Spacer(),
                TextButton(
                    onPressed: () {
                      GlobalKey<FormState> formKey = GlobalKey<FormState>();
                      AutovalidateMode autovalidateMode =
                          AutovalidateMode.disabled;
                      TextEditingController controller =
                          TextEditingController();
                      bool isLoading = false;
                      showDialog(
                          context: context,
                          builder: (_) => StatefulBuilder(
                                builder: (BuildContext context,
                                    StateSetter setStatee) {
                                  return AlertDialog(
                                      backgroundColor: Colors.white,
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Reset Password',
                                            style: TextStyle(fontSize: 18.sp),
                                          ),
                                          SizedBox(height: 10.h),
                                          Form(
                                              key: formKey,
                                              child: Column(
                                                children: [
                                                  TextFormField(
                                                    maxLength: 50,
                                                    autovalidateMode:
                                                        autovalidateMode,
                                                    validator: (value) {
                                                      if (value != null &&
                                                          value.trim() == '') {
                                                        return "password should'n be empty";
                                                      } else if (value !=
                                                              null &&
                                                          value.trim() !=
                                                              Constant
                                                                  .currentUser!
                                                                  .password
                                                                  .trim()) {
                                                        return 'Old password is not correct ';
                                                      }
                                                      return null;
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                            hintText:
                                                                'Old password'),
                                                  ),
                                                  SizedBox(height: 10.h),
                                                  TextFormField(
                                                    controller: controller,
                                                    maxLength: 50,
                                                    autovalidateMode:
                                                        autovalidateMode,
                                                    validator: (value) {
                                                      if (value != null &&
                                                              value.isEmpty ||
                                                          value!.length <= 6) {
                                                        return 'password should be mor than six characters';
                                                      }
                                                      return null;
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                            hintText:
                                                                'New password'),
                                                  ),
                                                ],
                                              )),
                                          SizedBox(height: 15.h),
                                          TextButton(
                                              onPressed: () async {
                                                if (!isLoading) {
                                                  autovalidateMode =
                                                      AutovalidateMode.always;
                                                  setStatee(() {});
                                                  if (formKey.currentState!
                                                      .validate()) {
                                                    isLoading = true;
                                                    setStatee(() {});
                                                    bool isConnected =
                                                        await InternetInfo
                                                            .isconnected();
                                                    if (context.mounted) {
                                                      if (isConnected) {
                                                        var isSuccess =
                                                            await context
                                                                .read<
                                                                    ProfileCubit>()
                                                                .changePassword(
                                                                    controller
                                                                        .text
                                                                        .trim());
                                                        if (isSuccess) {
                                                          if (context.mounted) {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          }
                                                        } else {
                                                          Toast.show(
                                                              'Something went wrog please try again',
                                                              duration: Toast
                                                                  .lengthLong);
                                                        }
                                                        isLoading = false;
                                                      } else {
                                                        isLoading = false;
                                                        Toast.show(
                                                            'Check you internet');
                                                        setStatee(() {});
                                                      }
                                                    }
                                                  }
                                                }
                                              },
                                              child: isLoading
                                                  ? const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                      color: Colors.black,
                                                    ))
                                                  : Text(
                                                      'Reset',
                                                      style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 20.sp),
                                                    ))
                                        ],
                                      ));
                                },
                              ));
                    },
                    child: const Text(
                      'Reset Password',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ))
              ]),
              SizedBox(height: 70.h),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  if (formKey.currentState!.validate()) {
                    widget.profileCubit.changeIsSaveButtonLoading(true);
                    bool isConnected = await InternetInfo.isconnected();
                    if (isConnected) {
                      UserModel user = UserModel(
                          cloudImgUrl: Constant.currentUser!.cloudImgUrl,
                          phoneNumber: phoneNumberController.text != ''
                              ? phoneNumberController.text.trim()
                              : null,
                          imgUrl: imgUrl,
                          email: emailController.text.trim(),
                          name: fullNameController.text.trim(),
                          password: Constant.currentUser!.password);
                      bool isSuccess =
                          await sl.get<DataSource>().updatePersonalData(user);
                      if (isSuccess) {
                        Constant.currentUser = user;
                        await sl
                            .get<SharedPreferences>()
                            .setString('currentUser', user.toJson());
                        widget.profileCubit.changeIsSaveButtonLoading(false);
                        if (context.mounted) {
                          goToHomePage(context);
                        }
                      } else {
                        if (context.mounted) {
                          Toast.show('Something went wrong please try again',
                              duration: Toast.lengthLong);
                        }
                      }
                    } else {
                      widget.profileCubit.changeIsSaveButtonLoading(false);
                      if (context.mounted) {
                        Toast.show('Check your internet connection',
                            duration: Toast.lengthLong);
                      }
                    }
                  }
                },
                child: Ink(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10)),
                  child: BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) {
                      return context.watch<ProfileCubit>().isSaveButtonLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : Text(
                              "Save",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp),
                            );
                    },
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void goToHomePage(BuildContext context) async {
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => MainPage(
              tabController:
                  TabController(vsync: this, length: 4, initialIndex: 3),
              pageController: PageController(initialPage: 3),
            )));
  }
}
