# 📚 FlutterShop – CMS & Data‑Expansion Documentation  
*(Generated for the current codebase – keep this file up‑to‑date whenever you add new features.)*  

---  

## Table of Contents
1. [Project Overview](#project-overview)  
2. [Installed Dependencies](#installed-dependencies)  
3. [Product Model & JSON Conversion](#product-model--json-conversion)  
4.  CMS Screen (`cms_screen.dart`)  
   - [Buttons & Actions](#buttons--actions)  
   - [How to Wire the CMS into Your App](#how-to-wire-the-cms-into-your-app)  
5. [Using the CMS – Step‑by‑Step](#using-the-cms-step‑by‑step)  
6. [Adding New Products via JSON](#adding-new-products-via-json)  
7. [Flushing / Clearing the Catalog](#flushing--clearing-the-catalog)  
8. [Future‑Proof Expansion Checklist](#future‑proof-expansion-checklist)  
9. [Troubleshooting](#troubleshooting)  

---  

## 1️⃣ Project Overview
**FlutterShop** is a premium e‑commerce UI kit (≈100 screens) that currently ships with hard‑coded demo product lists.  
The goal of this document is to give you a *single source of truth* for:

- How the demo data is structured.  
- How to replace it with real data (JSON upload).  
- How to add a simple CMS UI for on‑the‑fly changes.  
- What to keep in mind when extending the app later (new screens, extra fields, backend integration, etc.).

---  

## 2️⃣ Installed Dependencies
| Package | Current Version | Purpose |
|---------|----------------|---------|
| `file_picker` | `^5.3.0` | Platform‑native file picker (web, Windows, macOS, Linux, Android, iOS). |
| `flutter` | `3.50.0` (stable) | Whole framework. |
| `firebase_core`, `cloud_firestore` **(optional)** | – | If you later decide to replace the JSON‑based CMS with a real backend. |
| All other original packages (`flutter_svg`, `cached_network_image`, `animations`, …) | – | Unchanged – keep as‑is. |

> **Tip:** Run `flutter pub outdated` once in a while to keep compatibility.

---  

## 3️⃣ Product Model & JSON Conversion  

### 3.1 `lib/models/product_model.dart`

`ProductModel.fromJson` validates a product map, and `productModelFromJson` parses and validates a JSON array. The discount property names retain legacy spelling in the app model; JSON uses the clearer field names in the table below, which the parser maps to those properties.

### 3.2 What the helper does
- **`productModelFromJson(jsonString)`** → `List<ProductModel>`  
- Accepts any JSON array whose objects contain at least the fields:  

| Field | Type | Example |
|-------|------|---------|
| `image` | `String` (URL or local asset path) | `"https://example.com/img.jpg"` |
| `brandName` | `String` | `"Nike"` |
| `title` | `String` | `"Air Max 270"` |
| `price` | `num` (will be cast to `double`) | `150.00` |
| `priceAfterDiscount` | `num?` (optional) | `120.00` |
| `discountPercent` | `int?` (optional) | `20` |

`image`, `brandName`, `title`, and `price` are required. The discount fields are optional; malformed values or missing required fields produce a validation error, and the CMS keeps the previous catalog.

### 3.3 Adding a new field later
1. **Update `ProductModel`** – add the new `final` field and update the `fromJson` factory.  
2. **Update the demo lists** (if you want the new field to appear in the default UI).  
3. **Update any UI widgets** that display the field (e.g., add a `priceAfterDiscount` badge).  
4. **Optional** – add the field to the JSON schema you’ll upload later.

---  

## 4️⃣ CMS Screen (`cms_screen.dart`)  

### 4.1 Full file location
`lib/screens/cms_screen.dart`

Open the CMS from **Profile → Catalog CMS**.

### 4.2 Buttons & Actions

| Button | Code reference | What happens |
|--------|----------------|--------------|
| **Load Demo Data** | `void _loadDemo() => setState(() { _currentProducts = demoPopularProducts; … });` | Replaces the current product list with the static `demoPopularProducts` (you can point it at any of the other demo lists – just change the assignment). |
| **Flush (Clear)** | `void _flush() => setState(() { _currentProducts = []; … });` | Empties the list. The UI will show “No products – upload a catalog!” until you upload new data. |
| **Upload JSON Catalog** | `_uploadJson()` | Opens a file picker limited to `.json`, reads the selected bytes (including on web), validates the catalog, and replaces `_currentProducts`. Errors are shown in a message and do not replace the current catalog. |
| **Progress indicator** | `_isLoading` | Shown while the file picker is open and the file is being read. |

### 4.3 How to Wire the CMS into Your App

> **Scope:** This starter CMS keeps its catalog in the CMS screen's in-memory state. It does not persist data after leaving the screen or app restart, and it does not yet update the storefront's static demo lists. A shared repository and persistent storage/backend are needed for that.

### 4.3 Future: wiring into a product‑grid/home screen

The following is an integration direction, not behavior currently provided by the CMS:

```dart
// 1️⃣  Create a tiny ChangeNotifier (or use Provider/Riverpod/etc.)
class HomeModel extends ChangeNotifier {
  List<ProductModel> get products => _products;
  List<ProductModel> _products = demoPopularProducts; // default

  void setProducts(List<ProductModel> newProducts) {
    _products = newProducts;
    notifyListeners();
  }
}

// 2️⃣  Use it in your build function
Widget buildHomeScreen(BuildContext context) {
  final model = context.watch<HomeModel>();
  return Scaffold(
    appBar: AppBar(title: const Text('Home')),
    body: _buildProductGrid(model.products),
    bottomNavigationBar: const BottomNavBar(),
  );
}

// 3️⃣  Grid that consumes the *dynamic* list
Widget _buildProductGrid(List<ProductModel> products) {
  if (products.isEmpty) {
    return const Center(child: Text('No products – upload a catalog!'));
  }
  return GridView.builder(
    // … grid layout as before …
    itemCount: products.length,
    itemBuilder: (ctx, i) {
      final p = products[i];
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              ratio: 1.5,
              child: CachedNetworkImage(
                imageUrl: p.image,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 4),
            Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('\$${p.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            // … add rating, badge, etc.
          ],
        ),
      );
    },
  );
}
```

**Current CMS flow**

1. User opens **Profile → Catalog CMS**.
2. The CMS screen displays its own in-memory catalog and lets the user load demo data, clear it, or import JSON.
3. Storefront screens still use their existing static demo lists.

---  

## 5️⃣ Using the CMS – Step‑by‑Step

1. **Ensure the app is running** on a configured Flutter target (Android or iOS in this project).  
2. **Navigate to the CMS** from **Profile → Catalog CMS**.  
3. **Try each button:**  

   - **Load Demo** – the CMS list repopulates with the original demo items.  
   - **Flush** – the CMS list goes empty.  
   - **Upload JSON** – a file‑picker dialog appears.  
     - On **Windows/macOS** you’ll see a normal file‑system dialog.  
     - On **Web**, after adding web platform support, the browser provides the file picker dialog.  

4. **After selecting a file**, the CMS list updates with the products defined in that JSON. On web, select a local JSON file through the browser dialog.  

5. The loaded catalog is temporary and is lost when the CMS screen is discarded or the app restarts.

---  

## 6️⃣ Adding New Products via JSON  

### 6.1 Prepare a JSON file (example `assets/catalog.json`)

```json
[
  {
    "image": "https://example.com/p1.jpg",
    "brandName": "Nike",
    "title": "Air Max 270",
    "price": 150.00,
    "priceAfterDiscount": 120.00,
    "discountPercent": 20
  },
  {
    "image": "https://example.com/p2.jpg",
    "brandName": "Adidas",
    "title": "Ultraboost 22",
    "price": 180.00,
    "priceAfterDiscount": null,
    "discountPercent": null
  }
]
```

### 6.2 Declare the asset in `pubspec.yaml`

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/Illustration/
    - assets/flags/
    - assets/logo/
    - assets/screens/
    - assets/catalog.json   # <-- add this line
```

Run `flutter pub get` again (or let the IDE do it). This only bundles the file as an asset; the CMS's upload button opens the platform file picker and does not automatically load a bundled asset.

### 6.3 Upload from the CMS

1. Open the CMS.  
2. Tap **Upload JSON Catalog**.  
3. Browse to `catalog.json` (or any JSON you created).  
4. The app reads the file, converts each object to a `ProductModel`, and the product grid updates.

> **Tip:** If you want the JSON to be *bundled* with the APK/Web bundle, keep it under `assets/`. If you later move to a remote server, just change the file‑picker’s `allowedPaths` or replace the UI with a network‑fetch flow.

---  

## 7️⃣ Flushing / Clearing the Catalog  

- **Flush button** simply sets `_currentProducts = []`.  
- The UI will display the “No products – upload a catalog!” message until you upload new data.  
- If you want the **old data to disappear *before* the new JSON loads**, uncomment the line `_flush();` inside the `_uploadJson()` method of `cms_screen.dart`:

```dart
// inside _uploadJson():
// _flush();               // uncomment to flush before loading

final List<ProductModel> loaded = productModelFromJson(jsonString);
setState(() {
  _currentProducts = loaded;
  _isLoading = false;
});
```

---  

## 8️⃣ Future‑Proof Expansion Checklist  

| Area | What to watch / add | Quick‑fix example |
|------|---------------------|-------------------|
| **New product fields** (e.g., `rating`, `categoryId`) | Add `final` field to `ProductModel`, update `fromJson`, update any UI that displays it. | `final double? rating;` + `rating: json['rating'] as double?,` |
| **Category / tag system** | Add `CategoryModel` class, a `List<CategoryModel>` to `ProductModel`, or a separate `categories` list. Update screens to filter/facet. | ```dart class CategoryModel { final String id, name; }``` |
| **Backend integration** (Firebase, REST, GraphQL) | Replace the `productModelFromJson` helper with a repository that fetches from the backend. Keep the same model class so UI code doesn’t change. | ```dart Future<List<ProductModel>> fetchProducts() async { final snap = await FirebaseFirestore.instance.collection('products').get(); return snap.docs.map((d) => ProductModel.fromJson(d.data())).toList(); }``` |
| **Persistence across sessions** | Store the JSON string (or fetched data) with `shared_preferences`, `hive`, or `sqlite`. On app start, read the stored data and call `_currentProducts = ...`. | ```dart await SharedPreferences.getInstance().then((prefs) => prefs.setString('catalog', jsonString));``` |
| **Search / Filter UI** | Add text fields + `where` clauses on the product list (`where((p) => p.title.toLowerCase().contains(query))`). | ```dart final results = _currentProducts.where((p) => p.title.contains(searchQuery)).toList();``` |
| **Localization / i18n** | If you ever want multi‑language titles/brands, add `Map<String, String> titles` or separate `.arb` files and update the model. | ```dart final Map<String, String> altTitles;``` |
| **Theme switching** (light/dark) | Ensure all images/colors are vector‑compatible or provide dark‑mode assets. The existing `Theme.of(context)` usage already works. | No code change needed if you keep using `Theme.of(context).colorScheme...` |
| **Testing** | Add widget tests that pump the `ProductModel` list and assert UI elements. Keep the existing `test/widget_test.dart` as a pattern. | ```dart testWidgets('product card shows title', (WidgetTester tester) async { … });``` |

> **Keep this checklist handy** whenever you add a new feature. Updating the markdown file (this doc) with the new item will keep the knowledge base current.

---  

## 9️⃣ Troubleshooting  

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `FilePicker` does nothing on web | Missing `allowedExtensions` or the browser blocks the dialog because of CSP. | Ensure `file_picker: ^5.3.0` and that the page served over `http://` or `https://` (not `file://`). |
| “Invalid json format” error when uploading | JSON file missing required fields or has extra keys that don’t match `ProductModel.fromJson`. | Verify the JSON follows the schema: `image`, `brandName`, `title`, `price`, optional `priceAfterDiscount`, `discountPercent`. |
| Products not appearing after upload | The `ChangeNotifier`/`setState` not triggering a rebuild, or the list variable not being used by the UI. | Confirm the UI reads from the same `List<ProductModel>` that the CMS updates (e.g., `model.products` in the example). |
| App crashes on `_uploadJson` when file is large | Memory pressure on low‑end devices. | Consider streaming the file or limiting file size (`FilePicker.platform.pickFiles(…); if (picked!.files.single.size > 2*1024*1024) …`). |
| `ProductModel.fromJson` throws `TypeError` | JSON contains a field of wrong type (e.g., `price` is a string `"150"` instead of number). | Cast safely: `price: (json['price'] ?? 0)?.toDouble()` and add `??` defaults. |
| “Flutter run” fails after adding `file_picker` | Version conflict with other plugins. | Run `flutter pub upgrade` or pin versions in `pubspec.lock`. |

---  

## 🎯 Quick Recap

| What you have now | What to do next |
|-------------------|-----------------|
| **Demo data** + **JSON‑conversion helper** | Wire the CMS into any screen (see wiring snippet). |
| **CMS screen** with Load/Demo/Flush/Upload | Test each button; create a sample `catalog.json` and upload it. |
| **Future‑proof expansion checklist** | Add new fields, categories, or a real backend while keeping the same `ProductModel` interface. |
| **Documentation (this markdown)** | Keep it updated whenever you modify the model, add new screens, or change the data flow. |

---  

**Happy coding!** 🚀  
If you add a new feature or hit a snag, just open this doc, update the relevant section, and let me know – I’ll help you integrate it smoothly.