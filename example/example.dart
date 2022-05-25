import 'package:rapyd/rapyd.dart';

Future<void> main() async {
  final rapydClient = RapydClient('<rapydAccessKey>', '<rapydSecretKey>');

  try {
    final customer = await rapydClient.createNewCustomer(
      email: 'example@name.com',
      name: 'User',
    );

    print('Created customer successfully, ID: ${customer.data.id}');
  } catch (e) {
    print('ERROR: ${e.toString()}');
  }
}
