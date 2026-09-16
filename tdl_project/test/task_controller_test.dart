import 'package:flutter_test/flutter_test.dart';
import 'package:tdl_project/controllers/task_controller.dart';
import 'package:tdl_project/data/task_store.dart';

void main() {
  test('dữ liệu công việc được khôi phục từ kho lưu trữ', () async {
    final store = MemoryTaskStore();
    final firstController = TaskController(store: store);

    firstController.addTextTask(
      title: 'Việc cần làm',
      description: 'Dữ liệu vẫn còn sau khi mở lại ứng dụng',
      richTextJson: '[{"insert":"Nội dung"}]',
    );
    firstController.addDrawingTask(
      title: 'Bản vẽ',
      drawingJson: '[]',
      strokeCount: 1,
    );
    firstController.moveToTrash(firstController.activeTasks.first.id);
    await firstController.pendingWrites;

    final restoredController = TaskController(store: store);
    await restoredController.load();

    expect(restoredController.activeTasks, hasLength(1));
    expect(restoredController.deletedTasks, hasLength(1));
    expect(restoredController.deletedTasks.single.title, 'Việc cần làm');
    expect(
      restoredController.deletedTasks.single.description,
      'Dữ liệu vẫn còn sau khi mở lại ứng dụng',
    );
  });

  test('kho khách và kho tài khoản được giữ tách biệt', () async {
    final guestStore = MemoryTaskStore();
    final accountStore = MemoryTaskStore();
    final controller = TaskController(store: guestStore);

    controller.addTextTask(title: 'Việc của khách');
    await controller.pendingWrites;

    await controller.useStore(accountStore);
    expect(controller.activeTasks, isEmpty);
    controller.addTextTask(title: 'Việc của tài khoản');
    await controller.pendingWrites;

    await controller.useStore(guestStore);
    expect(controller.activeTasks.single.title, 'Việc của khách');

    await controller.useStore(accountStore);
    expect(controller.activeTasks.single.title, 'Việc của tài khoản');
  });
}
