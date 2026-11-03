# Flutter SQLite Applications – Lab Sheet 8

This project contains one Flutter application with menu-based modules covering the programs in the supplied Lab Sheet 8 PDF.

## Included modules
- Notes: add, display, search by title, edit by tapping, delete by swiping, SnackBar.
- Contact Book: add/display, search by name using SQL `LIKE`, delete with confirmation dialog.
- Expense Tracker: add/display expenses and calculate total using SQL `SUM`.
- To-Do: save tasks and update completion using a Checkbox.
- Registration/Login: save user details in SQLite and validate login.
- Form validation: required fields, numeric validation, email validation and minimum password length.
- Student Management: student list and add/edit/delete flow.
- Product Inventory: add, update and delete products.
- Shopping Cart: save items and calculate total price.

## Run the project
1. Install Flutter SDK and Android Studio (or another supported Flutter setup).
2. Extract this ZIP.
3. Open the extracted `flutter_sqlite_lab8` folder in VS Code.
4. In the terminal run:
   ```bash
   flutter pub get
   flutter run
   ```
5. For GitHub, create a repository and upload the project folder. You can also run `git init`, `git add .`, and `git commit -m "Flutter SQLite Lab Sheet 8"`.

## Important notes
- This ZIP contains the Flutter source (`lib/main.dart`) and dependency configuration. If your setup asks for Android/iOS platform folders, create them with `flutter create .` from this folder.
- SQLite data is stored locally on the device.
- This is an educational demonstration. The sample login stores passwords as plain text; do not use this approach in a real application. Real applications should use secure password hashing and proper authentication.
- The app uses a single integrated menu so the repeated “extend the application” exercises can be demonstrated in one project.
