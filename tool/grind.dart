import 'package:grinder/grinder.dart';

main(List<String> args) => grind(args);

@DefaultTask()
void analyze() {
  Analyzer.analyze(['.']);
}
