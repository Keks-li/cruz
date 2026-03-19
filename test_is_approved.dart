import 'dart:io';
void main() {
  var file = File('lib/features/agent/customers/lookup_client_screen.dart');
  print(file.readAsStringSync().contains("!isBackdated"));
}
