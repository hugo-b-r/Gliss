extension UtilsExt on String {
  List<String> multiSplit(Iterable<String> delimiters) => delimiters.isEmpty
      ? [this]
      : split(RegExp(delimiters.map(RegExp.escape).join('|')));
}
