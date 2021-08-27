class ValidationMixin {
  final RegExp ipRE =
      new RegExp(r"^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+)$");

  String? validateIP(String? value) {
    if (value != null && ipRE.hasMatch(value))
      return null;
    else
      return "Enter a valid IP address";
  }
}
