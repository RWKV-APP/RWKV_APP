enum CellType {
  empty,
  black,
  white;

  String get prompt {
    switch (this) {
      case CellType.empty:
        return "· ";
      case CellType.black:
        return "● ";
      case CellType.white:
        return "○ ";
    }
  }

  static CellType fromOutput(String output) {
    if (output == "○ ") return CellType.white;
    if (output == "● ") return CellType.black;
    return CellType.empty;
  }
}
