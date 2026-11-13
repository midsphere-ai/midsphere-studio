part of 'task.dart';

final fileSystemTools = {
  "tools": [
    {
      "name": "read_text_file",
      "title": "Read text file",
      "description":
          "Reading the complete contents of the file from the file system as text.",
      "annotations": {"readOnlyHint": true},
    },
    {
      "name": "read_media_file",
      "title": "Read media file",
      "description": "Reading the media file.",
      "annotations": {"readOnlyHint": true},
    },
    {
      "name": "read_multiple_files",
      "title": "Read Multiple Files",
      "description": "Reading the contents of multiple files simultaneously.",
      "annotations": {"readOnlyHint": true},
    },
    {
      "name": "write_file",
      "title": "Write File",
      "description":
          "Creating a new file or completely overwrite an existing file with new content. ",
      "annotations": {
        "readOnlyHint": false,
        "idempotentHint": true,
        "destructiveHint": true,
      },
    },
    {
      "name": "edit_file",
      "title": "Edit File",
      "description":
          "Making line-based edits to the file. Each edit replaces exact line sequences with new content.",
      "annotations": {
        "readOnlyHint": false,
        "idempotentHint": false,
        "destructiveHint": true,
      },
    },
    {
      "name": "create_directory",
      "title": "Create Directory",
      "description":
          "Creating a new directory or ensuring the directory exists.",
      "annotations": {
        "readOnlyHint": false,
        "idempotentHint": true,
        "destructiveHint": false,
      },
    },
    {
      "name": "list_directory",
      "title": "List Directory",
      "description":
          "Fetching a detailed listing of all files and directories in the specified path.",
      "annotations": {"readOnlyHint": true},
    },
    {
      "name": "list_directory_with_sizes",
      "title": "List Directory with Sizes",
      "description":
          "Fetching a detailed listing of all files and directories in the specified path, including sizes.",
      "annotations": {"readOnlyHint": true},
    },
    {
      "name": "directory_tree",
      "title": "Directory Tree",
      "description":
          "Fetching a recursive tree view of files and directories as a JSON structure.",
      "annotations": {"readOnlyHint": true},
    },
    {
      "name": "move_file",
      "title": "Move File",
      "description": "Moving or renaming files and directories. ",
      "annotations": {
        "readOnlyHint": false,
        "idempotentHint": false,
        "destructiveHint": false,
      },
    },
    {
      "name": "search_files",
      "title": "Search Files",
      "description":
          "Recursively searching for files and directories matching a pattern. ",
      "annotations": {"readOnlyHint": true},
    },
    {
      "name": "get_file_info",
      "title": "Get File Info",
      "description": "Retrieving detailed metadata about a file or directory.",
      "annotations": {"readOnlyHint": true},
    },
    {
      "name": "list_allowed_directories",
      "title": "List Allowed Directories",
      "description": "Fetching the list of directories in the workspace.",
      "annotations": {"readOnlyHint": true},
    },
  ],
};
