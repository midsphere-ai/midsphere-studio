import 'dart:convert';

import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/usecases/base.dart';
import 'package:flutter_client/logics/domain/usecases/cms/endpoint_enums.dart';
import 'package:flutter_client/logics/domain/usecases/memory/endpoint_enums.dart';
import 'package:flutter_client/logics/domain/usecases/spaces/endpoint_enums.dart';
import 'package:flutter_client/logics/domain/usecases/workspace/endpoint_enums.dart';
import 'package:flutter_client/logics/domain/usecases/workspace/workspace_usecase.dart';

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 24,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection("Workspace (Auth)", _buildWorkspaceTests()),
          _buildSection("Spaces", _buildSpacesTests()),
          _buildSection("CMS", _buildCMSTests()),
          _buildSection("Memory", _buildMemoryTests()),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title).h4,
        const SizedBox(height: 16),
        ...children,
        const Divider(),
      ],
    );
  }

  List<Widget> _buildWorkspaceTests() {
    return [
      MethodTester(
        name: "Login",
        parameters: const ["email", "password"],
        onRun: (params) async {
          return await WorkSpace.login({
            "email": params["email"],
            "password": params["password"],
          });
        },
      ),
      MethodTester(
        name: "Logout",
        parameters: const [],
        onRun: (params) async {
          return await WorkSpace.logout();
        },
      ),
      MethodTester(
        name: "Get User Info",
        parameters: const [],
        onRun: (params) async {
          return await WorkSpace.fetchUserInfo();
        },
      ),
      // Use Enums for others
      ...WorkspaceEndpoints.values.map((e) => EndpointTester(endpoint: e)),
    ];
  }

  List<Widget> _buildSpacesTests() {
    return SpacesEndpoints.values
        .map((e) => EndpointTester(endpoint: e))
        .toList();
  }

  List<Widget> _buildCMSTests() {
    return CMSEndpoints.values.map((e) => EndpointTester(endpoint: e)).toList();
  }

  List<Widget> _buildMemoryTests() {
    return MemoryEndpoints.values
        .map((e) => EndpointTester(endpoint: e))
        .toList();
  }
}

class EndpointTester extends StatelessWidget {
  final Endpoint endpoint;

  const EndpointTester({super.key, required this.endpoint});

  @override
  Widget build(BuildContext context) {
    return MethodTester(
      name:
          "${endpoint.requiredParams.method} ${endpoint.requiredParams.endpoint}",
      parameters: endpoint.requiredParams.parameters.cast<String>(),
      onRun: (params) async {
        // Handle pagination if needed, though strictly we are just testing the endpoint call here
        // If the usecase wrapper adds logic (like pagination), we might want to test the wrapper instead.
        // But for "testing endpoints", calling callEndpoint directly via wrapper or generic is fine.
        // However, some usecases expect 'repo' for pagination.
        // Let's check if the endpoint is paginated.
        // The Endpoint definition doesn't strictly say if it is paginated, but the UseCase wrapper does.
        // We will try calling it generically.

        return await NetworkConnector.callEndpoint(endpoint, params);
      },
    );
  }
}

class MethodTester extends StatefulWidget {
  final String name;
  final List<String> parameters;
  final Future<dynamic> Function(Map<String, dynamic>) onRun;

  const MethodTester({
    super.key,
    required this.name,
    required this.parameters,
    required this.onRun,
  });

  @override
  State<MethodTester> createState() => _MethodTesterState();
}

class _MethodTesterState extends State<MethodTester> {
  final Map<String, TextEditingController> _controllers = {};
  String? _result;
  bool _isLoading = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    for (var param in widget.parameters) {
      _controllers[param] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      borderRadius: Theme.of(context).borderRadiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.name),
          if (widget.parameters.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...widget.parameters.map((param) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _controllers[param],
                  placeholder: Text("Parameter: $param"),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              PrimaryButton(
                onPressed: _isLoading ? null : _runTest,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Run Test"),
              ),
              if (_result != null) ...[
                const SizedBox(width: 12),
                GhostButton(
                  onPressed: () {
                    setState(() {
                      _result = null;
                      _isError = false;
                    });
                  },
                  child: const Text("Clear"),
                ),
              ],
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isError
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: Theme.of(context).borderRadiusMd,
                border: Border.all(color: _isError ? Colors.red : Colors.green),
              ),
              child: SelectableText(
                _result!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: _isError ? Colors.red : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _isError = false;
    });

    try {
      final params = <String, dynamic>{};
      for (var entry in _controllers.entries) {
        // Simple type inference or just string
        // For now, let's treat everything as String unless it looks like a number or boolean?
        // Actually, API usually handles strings fine or we can try to parse.
        // Let's just pass strings for now, most APIs are JSON so types matter but simple POST params are often strings.
        // If strict typing is needed, we might need more metadata.
        params[entry.key] = entry.value.text;
      }

      final result = await widget.onRun(params);

      String resultString;
      if (result is Map || result is List) {
        resultString = const JsonEncoder.withIndent('  ').convert(result);
      } else {
        resultString = result.toString();
      }

      setState(() {
        _result = "Success:\n$resultString";
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _result = "Error:\n$e";
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
