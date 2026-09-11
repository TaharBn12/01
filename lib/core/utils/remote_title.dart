// جلب عنوان الفيديو عن بُعد — يتوفر فعليًّا على الأجهزة (dart:io)
// ويعيد null على الويب.
export 'remote_title_stub.dart'
    if (dart.library.io) 'remote_title_io.dart';
