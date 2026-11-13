/// A class that represents an MCP server.
class McpServer {
  /// The name of the server.
  final String name;

  /// The type of the server (stdio, sse, streamable-http).
  final String type;

  /// The command to start the server.
  final String? command;

  /// The arguments to pass to the server command.
  final String? args;

  /// The environment variables to set for the server.
  final String? env;

  /// A description of the server.
  final String? description;

  /// The URL of the server (for SSE/streamable-http).
  final String? url;

  /// The connection timeout in seconds.
  final int? timeout;

  /// The SSE read timeout in seconds.
  final int? sseReadTimeout;

  /// The client session timeout in seconds.
  final double? clientSessionTimeoutSeconds;

  /// Creates a new [McpServer] object.
  ///
  /// The [name] and [type] parameters are required.
  McpServer({
    required this.name,
    required this.type,
    this.command,
    this.args,
    this.env,
    this.description,
    this.url,
    this.timeout,
    this.sseReadTimeout,
    this.clientSessionTimeoutSeconds,
  });
}
