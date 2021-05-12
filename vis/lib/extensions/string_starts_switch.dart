
extension StringStartsSwitch on String {
  String startsSwitch({required List<String> values}) {
    for (var value in values) {
      if (this.startsWith(value)) {
        return value;
      }
    }
    return this;
  }
}
