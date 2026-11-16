import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/screens/cms_screen.dart';

void main() {
  group('productModelFromJson', () {
    test('parses required and optional catalog fields', () {
      final products = productModelFromJson(
        '[{"image":"item.png","brandName":"Brand","title":"Item",'
        '"price":12.5,"priceAfterDiscount":10,"discountPercent":20},'
        '{"image":"second.png","brandName":"Brand","title":"Second",'
        '"price":8}]',
      );

      expect(products, hasLength(2));
      expect(products.first.price, 12.5);
      expect(products.first.priceAfetDiscount, 10);
      expect(products.first.dicountpercent, 20);
      expect(products.last.priceAfetDiscount, isNull);
    });

    test('reports invalid catalog rows', () {
      expect(
        () => productModelFromJson(
          '[{"image":"item.png","brandName":"Brand","title":"Item","price":"12"}]',
        ),
        throwsFormatException,
      );
    });

    test('requires a JSON array', () {
      expect(() => productModelFromJson('{}'), throwsFormatException);
    });
  });

  testWidgets('CMS clears and restores its in-memory catalog', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CmsScreen()),
    );
    expect(find.text('Products loaded: 6'), findsOneWidget);

    await tester.tap(find.text('Flush (Clear)'));
    await tester.pumpAndSettle();
    expect(find.text('Products loaded: 0'), findsOneWidget);
    expect(
      find.text('No products — upload a catalog or load demo data.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Load Demo Data'));
    await tester.pumpAndSettle();
    expect(find.text('Products loaded: 6'), findsOneWidget);
  });
}
