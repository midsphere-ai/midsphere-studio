import 'package:hive_ce/hive.dart';
import '../logics/domain/entities/workspace/users/user.dart';

@GenerateAdapters([AdapterSpec<User>()])
part 'hive_adapters.g.dart';
