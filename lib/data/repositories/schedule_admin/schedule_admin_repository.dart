import '../../models/shift_template_model.dart';
import '../../models/working_schedule_admin_model.dart';

abstract class ScheduleAdminRepository {
  Future<List<ShiftTemplateModel>> getShiftTemplates();

  Future<ShiftTemplateModel> createShiftTemplate(CreateShiftTemplateInput input);

  Future<ShiftTemplateModel> updateShiftTemplate(
    String id,
    CreateShiftTemplateInput input,
  );

  Future<void> deleteShiftTemplate(String id);

  Future<WorkingScheduleListResult> getSchedules({
    int page = 1,
    int recordPerPage = 50,
    String? startDate,
    String? endDate,
  });

  Future<List<WorkingScheduleAdminModel>> createBulk(
    List<CreateWorkingScheduleInput> schedules,
  );

  Future<void> deleteSchedule(String id);
}
