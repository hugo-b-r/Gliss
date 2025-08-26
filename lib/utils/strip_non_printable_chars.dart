String stripNonPrintableChars(String strNonStrip) {
  var clean = strNonStrip.replaceAll(RegExp(r'[^A-Za-z0-9().,;?]'), ' ');
  return clean;
}