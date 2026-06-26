const List<String> _monthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

const List<String> _monthNamesShort = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

const List<String> _weekdayShort = [
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
  'Dom',
];

/// e.g. "Junho de 2026"
String formatMonthYear(DateTime month) {
  return '${_monthNames[month.month - 1]} de ${month.year}';
}

/// e.g. "12 de jun."
String formatDayMonth(DateTime date) {
  return '${date.day} de ${_monthNamesShort[date.month - 1].toLowerCase()}.';
}

/// e.g. "Qui, 12 de jun."
String formatWeekdayDayMonth(DateTime date) {
  final weekday = _weekdayShort[date.weekday - 1];
  return '$weekday, ${formatDayMonth(date)}';
}

DateTime stripTime(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isToday(DateTime date) => isSameDay(date, DateTime.now());
