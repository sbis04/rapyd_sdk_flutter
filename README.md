# Rapyd Flutter SDK

This is an **UNOFFICIAL** Flutter SDK for using [Rapyd APIs](https://docs.rapyd.net/build-with-rapyd/reference/api-reference) in Dart/Flutter apps.

> 🚧 **WIP (Disclaimer):** This package is in very early stage of development and has limited APIs to interact with. Feel free to contribute to this project as much as possible to make it production ready as soon as possible.

## Installation

Add this to your package's `pubspec.yaml` file:

```yml
dependencies:
  version: ^0.1.0
```

You can install packages from the command line:

```bash
pub get rapyd
```

## Usage

You can checkout the comprehensive example present in the [`example`](example/example.dart) folder.

Following is a simple example of initializing a Rapyd Client and creating a new user using this SDK:

```dart
// Initializing
final rapydClient = RapydClient('<access_key>', '<secret_key>');

try {
  // Creating a new customer
  final customer = await rapydClient.createNewCustomer(
    email: 'example@name.com',
    name: 'User',
  );
  print('Created customer successfully, ID: ${customer.data.id}');
} catch (e) {
  print('ERROR: ${e.toString()}');
}
```

## License

Copyright (c) 2022 Souvik Biswas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
