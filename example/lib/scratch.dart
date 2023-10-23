import 'dart:io';
void main() {

  final dependencies = {
    'FirebaseDatabase' : false,
    'FirebaseFirestore' : false,
    'FirebaseAuth' : false,
    'http.Client' : false,
  };
  for(final dependency in dependencies.entries) {
    final result = getTerminalInfo("does it use ${dependency.key}");
  var lastWord = dependency.key.split(RegExp('(?<=[a-z])(?=[A-Z])')).last;
  if(lastWord.contains('.')) {
    lastWord = lastWord.split(RegExp(r'\.')).last;
  }
    stdout.writeln('_${lastWord.toLowerCase()}');
    dependencies.update(dependency.key, (value) => result);
  }
  stdout.writeln(dependencies);

}

bool getTerminalInfo(String question) {
  stdout.write('$question (yes): ');
  final result = stdin.readLineSync() ?? 'yes';
  var value = true;
  if(result.isNotEmpty && result.toLowerCase() != 'yes' && result
      .toLowerCase() != 'y') {
    value = false;
  }
  return value;
}
