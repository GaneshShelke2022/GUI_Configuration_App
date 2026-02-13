// lib/services/Codec/cal_checksum.dart
class CalChecksum {
  static String checksum(List<String> hexData) {
    int sum = 0;
    // Iterate through the data bytes (byte count, address, record type, data)
    // The list 'hexData' contains 21 elements.
    // Index 0: Byte Count
    // Index 1-2: Address
    // Index 3: Record Type
    // Index 4-19: Data (16 bytes)
    // Index 20: Checksum (placeholder)

    // Sum all bytes from index 0 to 19
    for (int i = 0; i < 20; i++) {
      sum += int.parse(hexData[i], radix: 16);
    }

    // Calculate the two's complement of the least significant byte of the sum
    int complement = (256 - (sum % 256)) % 256;

    // Convert to a 2-character uppercase hex string
    return complement.toRadixString(16).padLeft(2, '0').toUpperCase();
  }
}
