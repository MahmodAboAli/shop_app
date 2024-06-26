import 'dart:developer';

import 'package:appwrite/models.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constant.dart';
import '../../../injection.dart';
import '../featurs/check_out/models/address_model.dart';
import '../featurs/home/models/product_model.dart';
import '../featurs/products_view/models/review_model.dart';
import 'data_source.dart';

class UpdateDeleteLocalDataSource {
  //! update section
  Future<void> updateQuantity(int id, int quantity) async {
    Database db = await openDatabase(Constant.addToCartTable);
    db.rawUpdate('UPDATE AddToCartTable SET quantity=$quantity WHERE id==$id');
  }

  Future<bool> updateAddress(
      AddressModel address, String oldAddressName) async {
    Database db = await openDatabase(Constant.locationsDataBasePath);
    try {
      if (await sl.get<DataSource>().updateLocationInCloud(address)) {
        await db.rawUpdate(
            "UPDATE locations SET firstName='${address.fullName}',lastName='${address.fullName}',phoneNumber='${address.phoneNumber}',emailAddress='${address.emailAddress}',addressName='${address.addressName}',longitude_code='${address.longitude}',latitude_code='${address.latitude}',city='${address.city}',country='${address.country}',address='${address.address}' WHERE addressName== '$oldAddressName'");
      } else {
        return false;
      }
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  Future<void> updateProductToNotDiscountUpdated(String productName) async {
    Database db = await openDatabase(Constant.productDataBasePath);
    try {
      db.rawUpdate(
          "UPDATE products SET isDiscountUpdated = 0 WHERE name='$productName'");
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> updateProductToNotNew(String productName) async {
    Database db = await openDatabase(Constant.productDataBasePath);
    db.rawUpdate("UPDATE products SET isNew = 0 WHERE name='$productName'");
  }

  Future<void> updateReviews() async {
    var data = sl.get<SharedPreferences>().getString('lastUpdate');
    if (data != null) {
      var newReviews = await sl.get<DataSource>().getUpdatedReviews(data);
      for (var element in newReviews) {
        ReviewModel reviewModel = ReviewModel.fromMap(element.data);
        sl.get<DataSource>().addReiviewToProduct(reviewModel);
      }
    }
    log('done');
  }

  Future<Either<Map<String, List<Document>>, bool>> updateDataBase() async {
    var data = sl.get<SharedPreferences>().getString('lastUpdate');
    Map<String, dynamic> personalData = {};
    if (data != null) {
      var res = await sl.get<DataSource>().getUpdatedProducts(data);
      bool s = res.fold((l) {
        personalData = l;
        return true;
      }, (r) {
        return false;
      });
      if (!s) {
        return Right(false);
      }
      List<Document> newProducts = personalData['newProducts'] ?? [];
      List<Document> updatedProducts = personalData['updatedProducts'] ?? [];
      if (newProducts.isNotEmpty) {
        if (!await sl
            .get<DataSource>()
            .insertProductsIntoLocalDataBase(newProducts, true)) {
          return Right(false);
        }
      }
      if (updatedProducts.isNotEmpty) {
        await updateProducts(updatedProducts);
      }
    }
    return Left({});
  }

  Future<bool> updateProducts(List<Document> products) async {
    Database db = await openDatabase(Constant.productDataBasePath);
    try {
      String names = '';
      for (var element in products) {
        log(element.data.toString());
        names += "'${element.data['name']}'|";
      }
      var len = names.length;
      names = names.substring(0, len - 1);
      var oldProducts = [];
      var res = await sl.get<DataSource>().getProductsByNames(names);
      bool s = res.fold((l) {
        oldProducts = l;
        return true;
      }, (r) {
        return false;
      });
      if (!s) {
        return false;
      }
      int index = 0;
      for (var element in products) {
        ProductModel newProduct = ProductModel.fromMap(element.data);
        if (element.data['isAvailable']) {
          db.rawUpdate("""
    UPDATE products SET name = ?, discription = ?, makerCompany = ?,sizes = ?,
    colors = ?,  date = ?, category = ? , price = ? ,discount = ?, isDiscountUpdated=?
     WHERE name = ? """, [
            newProduct.name,
            newProduct.discription,
            newProduct.makerCompany,
            newProduct.sizes,
            newProduct.colors,
            newProduct.date,
            newProduct.category,
            newProduct.price,
            newProduct.disCount,
            ProductModel.fromMap(oldProducts[index]).disCount ==
                    newProduct.disCount
                ? false
                : true,
            newProduct.name,
          ]);
        } else {
          var d = [];
          var res = await sl
              .get<DataSource>()
              .getProductsByNames("'${newProduct.name}'");
          var s = res.fold((l) {
            d = l;
            return true;
          }, (r) {
            return false;
          });
          if (!s) {
            return false;
          }
          Database recommendedDb =
              await openDatabase(Constant.recommendedProductsDataBasePath);
          await recommendedDb.rawDelete(
              "DELETE FROM recommended WHERE productId = ${ProductModel.fromMap(d[0]).id}");
          await db.rawDelete(
              "DELETE FROM products WHERE name = '${newProduct.name}'");
        }
        Database cartDb = await openDatabase(Constant.addToCartTable);
        cartDb.rawUpdate(
            """UPDATE AddToCartTable SET imgUrl = ?, productName = ? , price = ? , companyMaker = ?
        WHERE productName = ? """,
            [
              newProduct.imgUrl.split('|')[0],
              newProduct.name,
              newProduct.disCount > 0
                  ? (1 - newProduct.disCount / 100) * newProduct.price
                  : newProduct.price,
              newProduct.makerCompany,
              newProduct.name
            ]);
        index++;
      }
      log('done updating products');
      return true;
    } catch (e) {
      return false;
    }
  }

  //! delete section
  Future<void> deleteBorder(int borderId) async {
    Database db = await openDatabase(Constant.borderDataBasePath);
    await db.rawDelete('DELETE FROM borders WHERE id=$borderId');
    Database bDb = await openDatabase(Constant.broderProductsDataBasePath);
    await bDb.rawUpdate(
        'UPDATE borderProducts SET borderId=1 WHERE borderId=$borderId');
  }

  Future<Either<String, bool>> deleteAddress(AddressModel address) async {
    Database db = await openDatabase(Constant.locationsDataBasePath);
    bool isSuccess =
        await sl.get<DataSource>().deleteLocationFromCloud(address);
    if (isSuccess) {
      await db.rawDelete(
          'DELETE FROM locations WHERE addressName="${address.addressName}"');
      var data = await sl.get<DataSource>().getLocations();
      String? defaultLocation =
          sl.get<SharedPreferences>().getString('defaultLocation');
      if (data.isNotEmpty) {
        if (defaultLocation != null && defaultLocation == address.addressName) {
          await sl.get<SharedPreferences>().setString(
              'defaultLocation', AddressModel.fromMap(data[0]).addressName);
          return Left(AddressModel.fromMap(data[0]).addressName);
        } else {
          return Left(defaultLocation ?? '');
        }
      } else {
        await sl.get<SharedPreferences>().remove('defaultLocation');
        return Left('');
      }
    } else {
      return Right(false);
    }
  }

  Future<void> deleteWordFormSearchHistory(String word) async {
    Database db = await openDatabase(Constant.searchHistoryDataBasePath);
    db.rawDelete("DELETE FROM searchHistory WHERE word == '$word'");
  }

  Future<void> removeItemFromAddToCartProducts(int id) async {
    Database db = await openDatabase(Constant.addToCartTable);
    db.rawDelete('DELETE FROM AddToCartTable WHERE id == $id');
  }

  Future<void> deleteProductFromBorder(int productId) async {
    Database db = await openDatabase(Constant.broderProductsDataBasePath);
    await db
        .rawDelete('DELETE FROM borderProducts WHERE productId = $productId');
  }

  //! clear section
  Future<void> clearAddToCartTable() async {
    Database db = await openDatabase(Constant.addToCartTable);
    db.rawDelete('delete from AddToCartTable');
    log('add to cart table cleared');
  }

  Future<void> clearProductsTable() async {
    Database db = await openDatabase(Constant.addToCartTable);
    db.rawDelete('delete from products');
    log('add to cart table cleared');
  }

  Future<void> clearBordersTable() async {
    Database db = await openDatabase(Constant.borderDataBasePath);
    db.rawDelete("delete from borders");
    log('border table cleared');
  }

  Future<void> clearBorderPoducts() async {
    Database db = await openDatabase(Constant.broderProductsDataBasePath);
    db.rawDelete('delete from borderProducts');
    log(' borderProducts table cleared');
  }

  Future<void> clearOrdersTable() async {
    Database db = await openDatabase(Constant.ordersDataBasePath);
    db.rawDelete('delete from orders');
    log(' orders table cleared');
  }

  Future<void> clearLocationsTable() async {
    Database db = await openDatabase(Constant.locationsDataBasePath);
    db.rawDelete('delete from locations');
    log(' locations table cleared');
  }
}
