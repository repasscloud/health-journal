export 'catalogue_product.dart';
export 'catalogue_stub.dart'
    if (dart.library.io) 'catalogue_native.dart'
    show searchBundledCatalogue;
