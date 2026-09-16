import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:tdl_project/main.dart';
import 'package:tdl_project/models/task_item.dart';
import 'package:tdl_project/views/home/home_view.dart';
import 'package:tdl_project/views/tasks/drawing_task_view.dart';
import 'package:tdl_project/views/tasks/image_task_view.dart';
import 'package:tdl_project/widgets/drawing_preview.dart';
import 'package:tdl_project/widgets/image_preview.dart';
import 'package:tdl_project/widgets/rich_text_preview.dart';

void main() {
  testWidgets('hiển thị đầy đủ lựa chọn đăng nhập', (tester) async {
    await tester.pumpWidget(const TdlApp());

    expect(find.text('TO DO LIST'), findsOneWidget);
    expect(find.text('TLD'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('brand_logo'))),
      const Size(102, 102),
    );
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Tiếp tục không đăng nhập'), findsOneWidget);
  });

  testWidgets('nút Google phản hồi khi được nhấn', (tester) async {
    await tester.pumpWidget(const TdlApp());

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pump();

    expect(find.textContaining('Chưa cấu hình Supabase'), findsOneWidget);
  });

  testWidgets('chế độ khách mở màn hình chính và bảng đăng nhập', (
    tester,
  ) async {
    await tester.pumpWidget(const TdlApp());

    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_brand_logo')), findsOneWidget);
    expect(find.byKey(const Key('home_title')), findsOneWidget);
    expect(find.text('TDL'), findsOneWidget);
    expect(find.text('Chế độ khách'), findsNothing);
    expect(find.text('Chưa có công việc nào'), findsOneWidget);
    expect(find.byKey(const Key('task_search_field')), findsOneWidget);
    expect(find.byKey(const Key('sort_tasks_button')), findsOneWidget);
    expect(find.byKey(const Key('task_view_mode_button')), findsOneWidget);
    expect(find.byKey(const Key('trash_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('account_avatar_button')));
    await tester.pumpAndSettle();

    expect(find.text('Chế độ khách'), findsOneWidget);
    expect(find.byKey(const Key('home_google_sign_in_button')), findsOneWidget);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
    expect(find.byKey(const Key('theme_mode_switch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme_mode_switch')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.byKey(const Key('theme_mode_switch')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('tài khoản đã đăng nhập hiển thị nút đăng xuất', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeView(
          isSignedIn: true,
          tasks: const <TaskItem>[],
          onDeleteTask: (_) {},
          onOpenTask: (_) {},
          displayName: 'Nguyễn An',
          email: 'an@example.com',
          onGoogleSignIn: () {},
          onSignOut: () {},
          onThemeChanged: (_) {},
          onOpenTrash: () {},
          onCreateDrawing: () {},
          onCreateText: () {},
          onCreateImage: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('account_avatar_button')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text('an@example.com'), findsOneWidget);
    expect(find.byKey(const Key('sign_out_button')), findsOneWidget);
  });

  testWidgets('nút thêm công việc hiển thị ba loại nội dung', (tester) async {
    await tester.pumpWidget(const TdlApp());

    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_task_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_drawing_option')), findsOneWidget);
    expect(find.byKey(const Key('create_text_option')), findsOneWidget);
    expect(find.byKey(const Key('create_image_option')), findsOneWidget);
    expect(find.text('Bản vẽ'), findsOneWidget);
    expect(find.text('Văn bản'), findsOneWidget);
    expect(find.text('Hình ảnh'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create_image_option')));
    await tester.pumpAndSettle();
    expect(find.text('Ghi nhớ hình ảnh'), findsOneWidget);
    expect(find.byKey(const Key('pick_images_button')), findsOneWidget);
  });

  testWidgets('nút thùng rác mở danh sách công việc đã xóa', (tester) async {
    await tester.pumpWidget(const TdlApp());

    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trash_button')));
    await tester.pumpAndSettle();

    expect(find.text('Thùng rác'), findsOneWidget);
    expect(find.text('Thùng rác đang trống'), findsOneWidget);
  });

  testWidgets('tạo công việc văn bản và hiển thị trong danh sách', (
    tester,
  ) async {
    await tester.pumpWidget(const TdlApp());

    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_task_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_text_option')));
    await tester.pumpAndSettle();

    expect(find.text('Ghi chú mới'), findsOneWidget);
    expect(find.textContaining('Đã chỉnh sửa'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('text_task_title_field')),
      'Học Flutter',
    );
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    await tester.tap(find.byKey(const Key('text_task_description_field')));
    await tester.pump();
    expect(editor.focusNode.hasFocus, isTrue);

    const noteContent = 'Hoàn thành giao diện thêm công việc';
    editor.controller.replaceText(
      0,
      0,
      noteContent,
      const TextSelection.collapsed(offset: noteContent.length),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('undo_edit_button')));
    await tester.pump();
    expect(editor.controller.document.toPlainText().trim(), isEmpty);
    await tester.tap(find.byKey(const Key('redo_edit_button')));
    await tester.pump();
    expect(editor.controller.document.toPlainText().trim(), noteContent);
    editor.controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 9),
      ChangeSource.local,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('bold_format_button')));
    await tester.pump();

    expect(
      editor.controller.document.toDelta().toJson().toString(),
      contains('bold: true'),
    );
    editor.controller.updateSelection(
      const TextSelection(baseOffset: 10, extentOffset: 19),
      ChangeSource.local,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('text_color_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('text_color_2196F3')));
    await tester.pumpAndSettle();

    expect(
      editor.controller.document.toDelta().toJson().toString(),
      contains('color: #2196F3'),
    );
    editor.controller.updateSelection(
      const TextSelection(baseOffset: 10, extentOffset: 19),
      ChangeSource.local,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('text_color_button')));
    await tester.pumpAndSettle();
    final selectedColorChoice = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const Key('text_color_2196F3')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      (selectedColorChoice.decoration! as BoxDecoration).border,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('text_color_2196F3')));
    await tester.pumpAndSettle();

    expect(editor.controller.selection.isCollapsed, isTrue);
    final appendedOffset = editor.controller.selection.start;
    const appendedText = ' tiếp';
    editor.controller.replaceText(
      appendedOffset,
      0,
      appendedText,
      TextSelection.collapsed(offset: appendedOffset + appendedText.length),
    );
    await tester.pump();
    expect(
      editor.controller.document
          .collectStyle(appendedOffset, appendedText.length)
          .attributes[Attribute.color.key],
      isNull,
    );

    editor.controller.updateSelection(
      const TextSelection(baseOffset: 9, extentOffset: 10),
      ChangeSource.local,
    );
    editor.controller.replaceText(
      9,
      1,
      '',
      const TextSelection.collapsed(offset: 9),
    );
    await tester.pump();
    expect(
      editor.controller.document
          .collectStyle(9, 1)
          .attributes[Attribute.color.key]
          ?.value,
      '#2196F3',
    );
    editor.controller.replaceText(
      9,
      0,
      'x',
      const TextSelection.collapsed(offset: 10),
    );
    await tester.pump();
    expect(
      editor.controller.document
          .collectStyle(9, 1)
          .attributes[Attribute.color.key],
      isNull,
    );

    editor.controller.updateSelection(
      const TextSelection(baseOffset: 9, extentOffset: 10),
      ChangeSource.local,
    );
    editor.controller.replaceText(
      9,
      1,
      'y',
      const TextSelection.collapsed(offset: 10),
    );
    await tester.pump();
    expect(
      editor.controller.document
          .collectStyle(9, 1)
          .attributes[Attribute.color.key],
      isNull,
    );

    editor.controller.replaceText(
      10,
      0,
      'z',
      const TextSelection.collapsed(offset: 11),
    );
    await tester.pump();
    expect(
      editor.controller.document
          .collectStyle(10, 1)
          .attributes[Attribute.color.key],
      isNull,
    );
    editor.controller.replaceText(
      10,
      1,
      '',
      const TextSelection.collapsed(offset: 10),
    );
    await tester.pump();
    editor.controller.replaceText(
      10,
      0,
      'q',
      const TextSelection.collapsed(offset: 11),
    );
    await tester.pump();
    expect(
      editor.controller.document
          .collectStyle(10, 1)
          .attributes[Attribute.color.key],
      isNull,
    );
    expect(
      editor.controller.document
          .collectStyle(11, 1)
          .attributes[Attribute.color.key]
          ?.value,
      '#2196F3',
    );
    await tester.tap(find.byKey(const Key('save_text_task_button')));
    await tester.pumpAndSettle();

    expect(find.text('Học Flutter'), findsOneWidget);
    expect(find.byType(RichTextPreview), findsOneWidget);
    final previewEditor = tester.widget<QuillEditor>(
      find.descendant(
        of: find.byType(RichTextPreview),
        matching: find.byType(QuillEditor),
      ),
    );
    final previewDelta = previewEditor.controller.document
        .toDelta()
        .toJson()
        .toString();
    expect(previewDelta, contains('bold: true'));
    expect(previewDelta, contains('color: #2196F3'));

    final cardGrid = tester.widget<GridView>(find.byType(GridView));
    final cardDelegate =
        cardGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(cardDelegate.crossAxisCount, 2);

    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing);
    expect(find.byType(ListView), findsOneWidget);

    await tester.tap(find.text('Học Flutter'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa ghi chú'), findsOneWidget);
    final reopenedEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(
      reopenedEditor.controller.document.toDelta().toJson().toString(),
      contains('bold: true'),
    );
    expect(
      reopenedEditor.controller.document.toDelta().toJson().toString(),
      contains('color: #2196F3'),
    );

    await tester.enterText(
      find.byKey(const Key('text_task_title_field')),
      'Học Flutter nâng cao',
    );
    await tester.tap(find.byKey(const Key('save_text_task_button')));
    await tester.pumpAndSettle();

    expect(find.text('Học Flutter nâng cao'), findsOneWidget);
    expect(find.text('Học Flutter'), findsNothing);

    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.byKey(const Key('delete_task_button')));
    await tester.pumpAndSettle();
    expect(find.text('Xóa ghi chú?'), findsOneWidget);
    expect(find.text('Học Flutter nâng cao'), findsWidgets);
    await tester.tap(find.byKey(const Key('confirm_delete_task_button')));
    await tester.pumpAndSettle();
    expect(find.text('Học Flutter nâng cao'), findsNothing);

    await tester.tap(find.byKey(const Key('trash_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trash_task_grid')), findsOneWidget);
    final trashGrid = tester.widget<GridView>(
      find.byKey(const Key('trash_task_grid')),
    );
    final trashDelegate =
        trashGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(trashDelegate.crossAxisCount, 2);

    await tester.tap(find.byKey(const Key('delete_forever_button')));
    await tester.pumpAndSettle();
    expect(find.text('Xóa vĩnh viễn?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm_delete_forever_button')));
    await tester.pumpAndSettle();
    expect(find.text('Thùng rác đang trống'), findsOneWidget);
  });

  testWidgets('back auto-saves a note with content and ignores an empty note', (
    tester,
  ) async {
    await tester.pumpWidget(const TdlApp());
    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_task_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_text_option')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('text_task_title_field')),
      'Tự động lưu',
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Tự động lưu'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create_task_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_text_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Tự động lưu'), findsOneWidget);

    await tester.tap(find.text('Tự động lưu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('text_task_title_field')), '');
    await tester.tap(find.byKey(const Key('save_text_task_button')));
    await tester.pump();
    expect(find.text('Hãy nhập nội dung để lưu.'), findsOneWidget);
    expect(find.text('Chỉnh sửa ghi chú'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Tự động lưu'), findsNothing);
    expect(find.text('Chưa có công việc nào'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create_task_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_text_option')));
    await tester.pumpAndSettle();
    final untitledEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    const untitledContent = 'Nội dung không cần tiêu đề';
    untitledEditor.controller.replaceText(
      0,
      0,
      untitledContent,
      const TextSelection.collapsed(offset: untitledContent.length),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save_text_task_button')));
    await tester.pumpAndSettle();

    expect(find.byType(RichTextPreview), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('task_title_'),
      ),
      findsNothing,
    );
  });

  testWidgets('tạo bản vẽ, hoàn tác, làm lại và mở lại để chỉnh sửa', (
    tester,
  ) async {
    await tester.pumpWidget(const TdlApp());
    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_task_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_drawing_option')));
    await tester.pumpAndSettle();

    expect(find.text('Bản vẽ mới'), findsOneWidget);
    expect(find.byKey(const Key('drawing_undo_button')), findsOneWidget);
    expect(find.byKey(const Key('drawing_redo_button')), findsOneWidget);
    expect(find.byKey(const Key('drawing_pen_button')), findsOneWidget);
    expect(find.byKey(const Key('drawing_highlighter_button')), findsOneWidget);
    expect(find.byKey(const Key('drawing_eraser_button')), findsOneWidget);
    expect(find.text('Độ dày'), findsNothing);
    expect(find.textContaining('px'), findsNothing);
    expect(find.byKey(const Key('drawing_width_preview')), findsOneWidget);
    final widthSlider = tester.widget<Slider>(
      find.byKey(const Key('drawing_width_slider')),
    );
    expect(widthSlider.min, 1);
    expect(widthSlider.max, 30);

    await tester.tap(find.byKey(const Key('drawing_pen_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('drawing_color_palette')), findsOneWidget);
    final paletteColors = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('drawing_palette_color_');
    });
    expect(paletteColors, findsNWidgets(30));
    await tester.tap(paletteColors.at(14));
    await tester.pumpAndSettle();

    final canvasCenter = tester.getCenter(
      find.byKey(const Key('drawing_canvas')),
    );
    final firstFinger = await tester.createGesture(pointer: 21);
    final secondFinger = await tester.createGesture(pointer: 22);
    await firstFinger.down(canvasCenter - const Offset(24, 0));
    await secondFinger.down(canvasCenter + const Offset(24, 0));
    await firstFinger.moveBy(const Offset(35, 25));
    await secondFinger.moveBy(const Offset(35, 25));
    await firstFinger.up();
    await secondFinger.up();
    await tester.pump();

    await tester.dragFrom(
      canvasCenter - const Offset(50, 30),
      const Offset(100, 60),
    );
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('drawing_undo_button')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('drawing_undo_button')));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('drawing_redo_button')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('drawing_redo_button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('drawing_highlighter_button')));
    await tester.dragFrom(canvasCenter, const Offset(80, 0));
    await tester.pump();
    await tester.tap(find.byKey(const Key('drawing_eraser_button')));
    await tester.dragFrom(canvasCenter, const Offset(0, 55));
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_drawing_task_button')));
    await tester.pumpAndSettle();
    expect(find.byType(DrawingPreview), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('task_title_'),
      ),
      findsNothing,
    );
    expect(find.byIcon(Icons.draw_rounded), findsOneWidget);

    await tester.tap(find.byType(DrawingPreview));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa bản vẽ'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('drawing_undo_button')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('chọn nhiều ảnh, nhập nội dung và lưu công việc hình ảnh', (
    tester,
  ) async {
    const tinyPng =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    ImageTaskDraft? savedDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: ImageTaskView(
          pickImages: () async => [
            base64Decode(tinyPng),
            base64Decode(tinyPng),
          ],
          onSave: (draft) => savedDraft = draft,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pick_images_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selected_image_grid')), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    await tester.enterText(
      find.byKey(const Key('image_task_title_field')),
      'Ảnh cần nhớ',
    );
    await tester.enterText(
      find.byKey(const Key('image_task_content_field')),
      'Nội dung đi cùng hình ảnh',
    );
    await tester.tap(find.byKey(const Key('save_image_task_button')));
    await tester.pump();

    expect(savedDraft, isNotNull);
    expect(savedDraft!.title, 'Ảnh cần nhớ');
    expect(savedDraft!.description, 'Nội dung đi cùng hình ảnh');
    expect((jsonDecode(savedDraft!.imageDataJson) as List<dynamic>).length, 2);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 240,
          height: 140,
          child: ImagePreview(imageDataJson: savedDraft!.imageDataJson),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('canvas bản vẽ đổi sang nền tối theo giao diện', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: DrawingTaskView(onSave: (_) {}),
      ),
    );

    final canvasBackground = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(const Key('drawing_canvas')),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(canvasBackground.color, const Color(0xFF101820));
  });
}
