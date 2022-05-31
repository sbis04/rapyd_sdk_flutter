import 'dart:convert';
import 'dart:math';
import 'dart:developer' as dev;

import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../consts/consts.dart';
import '../models/models.dart';

/// {@template RapydClient}
/// The client for getting access to all the Rapyd APIs.
///
/// Provide the Rapyd `access key` and the `secret key` while initializing
/// the client. For example:
///
/// ```dart
/// final rapydClient = RapydClient('<access_key>', '<secret_key>');
/// ```
///
/// It's recommended to do the initialization globally inside a Flutter app,
/// so that you can access the `rapydClient` object from any page.
/// {@endtemplate}
///
class RapydClient {
  final String _accessKey;
  final String _secretKey;

  /// {@macro RapydClient}
  RapydClient(this._accessKey, this._secretKey);

  /// Generates the salt required for [signature calculation](https://docs.rapyd.net/build-with-rapyd/reference/message-security#calculation-of-signature).
  ///
  /// ### According to Rapyd API specs:
  ///
  /// **Salt** is a random string for each request. Length: 8-16 digits,
  /// letters and special characters.
  ///
  /// This method generates a salt of encoded 16 random bytes and returns it as
  /// a `String`.
  ///
  String _generateSalt() {
    final random = Random.secure();
    // Generate 16 characters for salt by generating 16 random bytes
    // and encoding it.
    final randomBytes = List<int>.generate(16, (index) => random.nextInt(256));
    return base64UrlEncode(randomBytes);
  }

  /// Generates the header required for performing any API call to Rapyd.
  ///
  /// It takes three parameters:
  ///
  /// * [method] The type of HTTP request (get, post, etc - should be in
  /// lowercase).
  ///
  /// * [endpoint] The endpoint path leaving out the base URL.
  ///
  /// * [body] (optional) In case of a method call like `post` the body should
  /// be provided.
  ///
  /// Returns the header as `Map<String, String>`.
  ///
  /// The most important part in the header is the signature calculation. It
  /// is calculated in Rapyd using the following formula:
  ///
  /// ```
  /// signature = BASE64 ( HASH ( http_method + url_path + salt + timestamp + access_key + secret_key + body_string ) )
  /// ```
  ///
  Map<String, String> _generateHeader({
    required String method,
    required String endpoint,
    String body = '',
  }) {
    int unixTimestamp = DateTime.now().millisecondsSinceEpoch;
    String timestamp = (unixTimestamp / 1000).round().toString();

    var salt = _generateSalt();

    var toSign =
        method + endpoint + salt + timestamp + _accessKey + _secretKey + body;

    var keyEncoded = ascii.encode(_secretKey);
    var toSignEncoded = ascii.encode(toSign);

    var hmacSha256 = Hmac(sha256, keyEncoded); // HMAC-SHA256
    var digest = hmacSha256.convert(toSignEncoded);
    var ss = hex.encode(digest.bytes);
    var tt = ss.codeUnits;
    var signature = base64.encode(tt);

    var headers = {
      'Content-Type': 'application/json',
      'access_key': _accessKey,
      'salt': salt,
      'timestamp': timestamp,
      'signature': signature,
    };

    return headers;
  }

  /// Used for generating a new checkout object.
  ///
  /// The required parameters are [amount], [currency], [countryCode], and
  /// [customerId]
  ///
  /// * [amount] has to be passed as a `String`.
  ///
  ///
  /// * [currency] of the country, has to be passed as a `String`.
  ///
  ///
  /// * [countryCode] from where the payment is being processed,
  /// has to be passed as a `String`.
  ///
  ///
  /// * [customerId] of the customer, has to be passed as a `String`.
  ///
  ///
  /// The optional parameters are:
  ///
  /// * [orderNumber] that you may want to associate with this checkout,
  /// maybe helpful while generating invoice for the order.
  ///
  /// * [completePaymentURL] the URL where you want to redirect the user
  /// after completion of a successful transaction.
  ///
  ///
  /// * [errorPaymentURL] the URL where you want to redirect the user
  /// after completion of a failed transaction.
  ///
  ///
  /// * [merchantReferenceId] to be associated with the checkout.
  ///
  ///
  /// * [paymentMethods] that should be accepted, more information
  /// [here](https://docs.rapyd.net/build-with-rapyd/docs/payment-methods).
  ///
  ///
  /// * [useCardholdersPreferredCurrency] whether to accept the card holder's
  /// preferred currency. By default, it's set to `true`.
  ///
  ///
  /// * [languageCode] By default, it's set to `en` (English).
  ///
  Future<Checkout?> createCheckout({
    required String amount,
    required String currency,
    required String countryCode,
    required String customerId,
    String? orderNumber,
    String? completePaymentURL,
    String? errorPaymentURL,
    String? merchantReferenceId,
    List<String>? paymentMethods,
    bool useCardholdersPreferredCurrency = true,
    String languageCode = 'en',
  }) async {
    Checkout? checkoutDetails;

    var method = "post";
    var checkoutEndpoint = '/v1/checkout';

    final checkoutURL = Uri.parse(baseURL + checkoutEndpoint);

    var data = jsonEncode({
      "amount": amount,
      "complete_payment_url": completePaymentURL,
      "country": countryCode,
      "currency": currency,
      "error_payment_url": errorPaymentURL,
      "merchant_reference_id": merchantReferenceId,
      "cardholder_preferred_currency": useCardholdersPreferredCurrency,
      "language": languageCode,
      "metadata": {
        "merchant_defined": true,
        "sales_order": orderNumber,
      },
      "payment_method_types_include": paymentMethods,
      "customer": customerId,
    });

    final headers = _generateHeader(
      method: method,
      endpoint: checkoutEndpoint,
      body: data,
    );

    try {
      var response = await http.post(
        checkoutURL,
        headers: headers,
        body: data,
      );

      if (response.statusCode == 200) {
        dev.log('SUCCESSFULLY CHECKOUT');
        checkoutDetails = Checkout.fromJson(jsonDecode(response.body));
      } else {
        dev.log(response.statusCode.toString());
      }
    } catch (e) {
      dev.log('Failed to generate the checkout');
    }

    return checkoutDetails;
  }

  /// Used for retrieving a checkout object.
  ///
  Future<PaymentStatus?> retrieveCheckout({required String checkoutId}) async {
    PaymentStatus? paymentStatus;

    var method = "get";
    var checkoutEndpoint = '/v1/checkout/$checkoutId';

    final checkoutURL = Uri.parse(baseURL + checkoutEndpoint);

    final headers = _generateHeader(
      method: method,
      endpoint: checkoutEndpoint,
    );

    try {
      var response = await http.get(checkoutURL, headers: headers);

      if (response.statusCode == 200) {
        dev.log('Checkout retrieved successfully!');
        paymentStatus = PaymentStatus.fromJson(jsonDecode(response.body));
      } else {
        throw ('Failed to retrieve the checkout, status ${response.statusCode}');
      }
    } catch (_) {
      dev.log('Failed to retrieve checkout');
    }

    return paymentStatus;
  }

  /// Used for creating a new customer on Rapyd.
  ///
  Future<Customer> createNewCustomer({
    required String email,
    required String name,
  }) async {
    late Customer customerDetails;

    var method = "post";
    var checkoutEndpoint = '/v1/customers';

    final checkoutURL = Uri.parse(baseURL + checkoutEndpoint);

    var data = jsonEncode({
      "email": email,
      "name": name,
      "metadata": {
        "merchant_defined": true,
      },
    });

    final headers = _generateHeader(
      method: method,
      endpoint: checkoutEndpoint,
      body: data,
    );

    try {
      var response = await http.post(
        checkoutURL,
        headers: headers,
        body: data,
      );

      if (response.statusCode == 200) {
        dev.log('CUSTOMER SUCCESSFULLY CREATED');
        customerDetails = Customer.fromJson(jsonDecode(response.body));
      } else {
        throw ('Failed to create new customer, status ${response.statusCode}');
      }
    } catch (e) {
      dev.log('Failed to create a customer');
    }

    return customerDetails;
  }

  /// Used for adding a new payment method to a customer object.
  ///
  Future<CardPayment?> addPaymentMethodToCustomer({
    required String customerId,
    required String type,
    required String number,
    required String expirationMonth,
    required String expirationYear,
    required String cvv,
    required String cardHoldersName,
  }) async {
    CardPayment? cardDetails;

    var method = "post";
    var checkoutEndpoint = '/v1/customers/$customerId/payment_methods';

    final checkoutURL = Uri.parse(baseURL + checkoutEndpoint);

    var data = jsonEncode({
      "type": type,
      "fields": {
        "number": number,
        "expiration_month": expirationMonth,
        "expiration_year": expirationYear,
        "cvv": cvv,
        "name": cardHoldersName,
      },
      "metadata": {
        "merchant_defined": true,
      },
    });

    final headers = _generateHeader(
      method: method,
      endpoint: checkoutEndpoint,
      body: data,
    );

    try {
      var response = await http.post(
        checkoutURL,
        headers: headers,
        body: data,
      );

      if (response.statusCode == 200) {
        dev.log('PAYMENT METHOD SUCCESSFULLY ADDED');
        cardDetails = CardPayment.fromJson(jsonDecode(response.body));
      } else {
        dev.log(response.statusCode.toString());
      }
    } catch (e) {
      dev.log('Failed to create the payment method');
    }

    return cardDetails;
  }

  // Future<Wallet?> getWalletDetails({required String walletID}) async {
  //   Wallet? retrievedWallet;

  //   var method = "get";
  //   var walletEndpoint = '/v1/user/$walletID';

  //   final walletURL = Uri.parse(_baseURL + walletEndpoint);

  //   final headers = _generateHeader(
  //     method: method,
  //     endpoint: walletEndpoint,
  //   );

  //   try {
  //     var response = await http.get(walletURL, headers: headers);

  //     dev.log(response.body);

  //     if (response.statusCode == 200) {
  //       dev.log('Wallet retrieved successfully!');
  //       retrievedWallet = Wallet.fromJson(jsonDecode(response.body));
  //     }
  //   } catch (_) {
  //     dev.log('Failed to retrieve wallet');
  //   }

  //   return retrievedWallet;
  // }

  // Future<Transfer?> transferMoney({
  //   required String sourceWallet,
  //   required String destinationWallet,
  //   required int amount,
  // }) async {
  //   Transfer? transferDetails;

  //   var method = "post";
  //   var transferEndpoint = '/v1/account/transfer';

  //   final transferURL = Uri.parse(_baseURL + transferEndpoint);

  //   var data = jsonEncode({
  //     "source_ewallet": sourceWallet,
  //     "amount": amount,
  //     "currency": "USD",
  //     "destination_ewallet": destinationWallet,
  //   });

  //   final headers = _generateHeader(
  //     method: method,
  //     endpoint: transferEndpoint,
  //     body: data,
  //   );

  //   try {
  //     var response = await http.post(
  //       transferURL,
  //       headers: headers,
  //       body: data,
  //     );

  //     dev.log(response.body);

  //     if (response.statusCode == 200) {
  //       dev.log('SUCCESSFULLY TRANSFERED');
  //       transferDetails = Transfer.fromJson(jsonDecode(response.body));
  //     }
  //   } catch (e) {
  //     dev.log('Failed to transfer amount');
  //   }

  //   return transferDetails;
  // }

  // Future<Transfer?> transferResponse({
  //   required String id,
  //   required String response,
  // }) async {
  //   Transfer? transferDetails;

  //   var method = "post";
  //   var responseEndpoint = '/v1/account/transfer/response';

  //   final responseURL = Uri.parse(_baseURL + responseEndpoint);

  //   var data = jsonEncode({
  //     "id": id,
  //     "status": response,
  //   });

  //   final headers = _generateHeader(
  //     method: method,
  //     endpoint: responseEndpoint,
  //     body: data,
  //   );

  //   try {
  //     var response = await http.post(
  //       responseURL,
  //       headers: headers,
  //       body: data,
  //     );

  //     dev.log(response.body);

  //     if (response.statusCode == 200) {
  //       dev.log('TRANSFER STATUS UPDATED: $response');
  //       transferDetails = Transfer.fromJson(jsonDecode(response.body));
  //     }
  //   } catch (e) {
  //     dev.log('Failed to update transfer status');
  //   }

  //   return transferDetails;
  // }
}
