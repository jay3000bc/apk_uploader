convertPriceToNumber(String price, String decimalSeparator) {
  double priceDouble = double.parse(price);
  price = priceDouble.toStringAsFixed(2);

  if (decimalSeparator == ',') {
    price = price.replaceAll('.', ',');
  } else if (decimalSeparator == '.') {
    price = price.replaceAll(',', '');
  }

  return price;
}
