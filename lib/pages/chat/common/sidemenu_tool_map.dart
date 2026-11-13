part of 'sidemenu.dart';

final toolMap = {
  // ===== audio.py =====
  "mcp_audio_transcription": {
    "arg": "audio_path",
    "body": "editor",
    "message": "Transcribing audio from {audio_path}",
  },
  "mcp_audio_question_answering": {
    "arg": "audio_path_or_url",
    "body": "editor",
    "message": "{question} in {audio_path_or_url}",
  },

  // ===== code.py =====
  "mcp_run_shell_command": {
    "arg": "command",
    "body": "terminal",
    "message": "Running shell command",
  },
  "mcp_run_python_code": {
    "arg": "",
    "body": "arg[code_block]",
    "message": "Executing Python code",
  },

  // ===== download.py =====
  "mcp_download_file": {
    "arg": "url",
    "body": "editor",
    "message": "Downloading file from {url}",
  },

  // ===== file.py =====
  "get_reference_projects": {
    "arg": "",
    "body": "map[projects]",
    "message": "Looking for reference projects",
  },
  "read_reference_file": {
    "arg": "file_path",
    "body": "editor",
    "message": "Reading {file_path} from {reference_name}",
  },
  "list_reference_directory": {
    "arg": "reference_name",
    "body": "list",
    "message": "Reading all files and folders from {reference_name}",
  },
  "list_directory": {
    "arg": "",
    "body": "list",
    "message": "Reading all files and folders from workspace directory",
  },
  "read_file": {
    "arg": "file_path",
    "body": "editor",
    "message": "Reading {file_path}",
  },
  "save_file": {
    "arg": "file_path",
    "body": "editor[content]",
    "message": "Writing content to {file_path}",
  },
  "append_file": {
    "arg": "file_path",
    "body": "editor[content]",
    "message": "Appending content to {file_path}",
  },
  "delete_this_file": {
    "arg": "file_path",
    "body": "confirmation",
    "message": "Deleting {file_path}",
  },
  "move_file": {
    "arg": "source_path",
    "body": "confirmation",
    "message": "Moving {source_path} to {destination_path}",
  },
  "edit_file": {
    "arg": "file_path",
    "body": "diff_viewer",
    "message": "Editing {file_path}",
  },
  "run_server": {
    "arg": "project_dir",
    "body": "confirmation",
    "message": "Opening editor in {project_dir}",
  },

  // ===== media_gen.py =====
  "mcp_create_genai_image": {
    "arg": "prompt",
    "body": "image_preview",
    "message": "Generating image: {prompt}",
  },
  "mcp_edit_genai_image": {
    "arg": "prompt",
    "body": "image_preview",
    "message": "Editing image with: {prompt}",
  },
  "mcp_create_genai_video": {
    "arg": "prompt",
    "body": "video_preview",
    "message": "Generating video: {prompt}",
  },
  "mcp_create_genai_video_with_frames": {
    "arg": "prompt",
    "body": "video_preview",
    "message": "Generating video with frames: {prompt}",
  },
  "mcp_extend_genai_video": {
    "arg": "video_path",
    "body": "video_preview",
    "message": "Extending video: {video_path}",
  },
  "mcp_python_repl_tool": {
    "arg": "",
    "body": "arg[code]",
    "message": "Executing Python code",
  },
  "mcp_shell_tool": {
    "arg": "command",
    "body": "terminal",
    "message": "Running shell command",
  },
  "mcp_download_from_gcs": {
    "arg": "gcs_url",
    "body": "editor",
    "message": "Downloading from {gcs_url}",
  },

  // ===== mobile.py =====
  "mcp_flutter_project_init": {
    "arg": "project_name",
    "body": "confirmation",
    "message": "Initializing Flutter project: {project_name}",
  },
  "mcp_set_current_project": {
    "arg": "project_name",
    "body": "confirmation",
    "message": "Setting current project to {project_name}",
  },
  "mcp_list_projects": {
    "arg": "",
    "body": "list",
    "message": "Listing all projects in workspace",
  },
  "create_checkpoint": {
    "arg": "commit_message",
    "body": "confirmation",
    "message": "Creating checkpoint: {commit_message}",
  },
  "mcp_list_checkpoints": {
    "arg": "",
    "body": "list[hash, message, date]",
    "message": "Listing project checkpoints",
  },
  "mcp_rollback_checkpoint": {
    "arg": "commit_hash",
    "body": "confirmation",
    "message": "Rolling back to {commit_hash}",
  },
  "mcp_run_local_command": {
    "arg": "command",
    "body": "terminal",
    "message": "Running command: {command}",
  },

  // ===== plan.py =====
  "mcp_advance_plan": {
    "arg": "next_phase_id",
    "body": "plan_viewer",
    "message": "Advancing to phase {next_phase_id}",
  },
  "mcp_update_plan": {
    "arg": "goal",
    "body": "plan_viewer",
    "message": "Updating plan: {goal}",
  },
  "mcp_get_plan": {
    "arg": "",
    "body": "plan_viewer",
    "message": "Retrieving current plan",
  },
  "mcp_message": {
    "arg": "content",
    "body": "editor",
    "message": "Sending message to user",
  },

  // ===== read.py =====
  "mcp_read_resource_file": {
    "arg": "uri",
    "body": "editor",
    "message": "Reading resource from {uri}",
  },

  // ===== reasoning.py =====
  "mcp_complex_reasoning": {
    "arg": "question",
    "body": "editor",
    "message": "Reasoning: {question}",
  },
  "mcp_guard_reasoning": {
    "arg": "question",
    "body": "editor",
    "message": "Validating reasoning: {question}",
  },

  // ===== search.py =====
  "mcp_use_browser": {
    "arg": "task",
    "body": "editor",
    "message": "Browsing: {task}",
  },
  "mcp_scrape_url": {
    "arg": "url",
    "body": "editor",
    "message": "Scraping content from {url}",
  },
  "mcp_search_google": {
    "arg": "query",
    "body": "list[title, url, snippet]",
    "message": "Searching Google: {query}",
  },
  "mcp_download_youtube_video": {
    "arg": "url",
    "body": "video_preview",
    "message": "Downloading YouTube video: {url}",
  },
  "mcp_search_wikipedia": {
    "arg": "query",
    "body": "list[title, url]",
    "message": "Searching Wikipedia: {query}",
  },
  "mcp_get_wikipedia_article": {
    "arg": "title",
    "body": "editor",
    "message": "Fetching Wikipedia article: {title}",
  },
  "mcp_get_wikipedia_summary": {
    "arg": "title",
    "body": "editor",
    "message": "Getting Wikipedia summary: {title}",
  },
  "mcp_get_wikipedia_article_history": {
    "arg": "title",
    "body": "editor",
    "message": "Fetching historical article: {title} on {date}",
  },

  // ===== slides.py =====
  "mcp_list_presentation_templates": {
    "arg": "",
    "body": "list[name, description]",
    "message": "Listing presentation templates",
  },
  "mcp_load_template_presentation_design": {
    "arg": "template_name",
    "body": "editor",
    "message": "Loading template: {template_name}",
  },
  "mcp_create_slide": {
    "arg": "slide_number",
    "body": "editor[html_content]",
    "message": "Creating slide {slide_number} for {presentation_name}",
  },
  "mcp_list_slides": {
    "arg": "presentation_name",
    "body": "list[number, preview]",
    "message": "Listing slides in {presentation_name}",
  },
  "mcp_delete_slide": {
    "arg": "slide_number",
    "body": "confirmation",
    "message": "Deleting slide {slide_number} from {presentation_name}",
  },
  "mcp_list_presentations": {
    "arg": "",
    "body": "list[name, slide_count]",
    "message": "Listing all presentations",
  },
  "mcp_delete_presentation": {
    "arg": "presentation_name",
    "body": "confirmation",
    "message": "Deleting presentation: {presentation_name}",
  },
  "mcp_validate_slide": {
    "arg": "slide_number",
    "body": "editor",
    "message": "Validating slide {slide_number} in {presentation_name}",
  },
  "mcp_export_presentation": {
    "arg": "presentation_name",
    "body": "confirmation",
    "message": "Exporting {presentation_name} to {format}",
  },

  // ===== vision.py =====
  "mcp_visual_question_answering": {
    "arg": "image_path_or_url",
    "body": "editor",
    "message": "{question} in {image_path_or_url}",
  },
  "mcp_visual_audio_youtube_analyzing": {
    "arg": "youtube_url",
    "body": "editor",
    "message": "Analyzing YouTube video: {youtube_url}",
  },
  "mcp_analyze_local_video": {
    "arg": "video_path",
    "body": "editor",
    "message": "Analyzing video: {video_path}",
  },
  "mcp_summarize_local_video": {
    "arg": "video_path",
    "body": "editor",
    "message": "Summarizing video: {video_path}",
  },
  "mcp_extract_keyframes": {
    "arg": "video_path",
    "body": "list[frame_time, frame_path]",
    "message": "Extracting keyframes from {video_path}",
  },
  "mcp_compare_multiple_images": {
    "arg": "image_paths",
    "body": "editor",
    "message": "Comparing {image_paths.length} images",
  },
  "mcp_compare_multiple_videos": {
    "arg": "video_paths",
    "body": "editor",
    "message": "Comparing {video_paths.length} videos",
  },

  // ===== web.py =====
  "mcp_copy_web_template": {
    "arg": "project_name",
    "body": "confirmation",
    "message": "Creating project {project_name} from {template_name}",
  },
  "mcp_set_current_web_project": {
    "arg": "project_name",
    "body": "confirmation",
    "message": "Setting current project to {project_name}",
  },
  "mcp_add_env_variable": {
    "arg": "key",
    "body": "confirmation",
    "message": "Adding env variable {key}",
  },
  "mcp_remove_env_variable": {
    "arg": "key",
    "body": "confirmation",
    "message": "Removing env variable {key}",
  },
  "mcp_list_env_variables": {
    "arg": "env_file",
    "body": "list[key, value]",
    "message": "Listing env variables from {env_file}",
  },
  "mcp_create_checkpoint": {
    "arg": "commit_message",
    "body": "confirmation",
    "message": "Creating checkpoint: {commit_message}",
  },
  "mcp_execute_sql_query": {
    "arg": "query",
    "body": "table",
    "message": "Executing SQL query",
  },
  "mcp_list_database_tables": {
    "arg": "",
    "body": "list[name, row_count]",
    "message": "Listing database tables",
  },
  "mcp_start_dev_server": {
    "arg": "port",
    "body": "confirmation",
    "message": "Starting dev server on port {port}",
  },
  "mcp_stop_dev_server": {
    "arg": "",
    "body": "confirmation",
    "message": "Stopping dev server",
  },
  "mcp_restart_dev_server": {
    "arg": "port",
    "body": "confirmation",
    "message": "Restarting dev server on port {port}",
  },
  "mcp_server_status": {
    "arg": "",
    "body": "map[status, url, port]",
    "message": "Checking server status",
  },
  "mcp_install_dependencies": {
    "arg": "",
    "body": "terminal",
    "message": "Installing npm dependencies",
  },
  "mcp_start_expo_server": {
    "arg": "port",
    "body": "confirmation",
    "message": "Starting Expo server on port {port}",
  },
  "mcp_stop_expo_server": {
    "arg": "",
    "body": "confirmation",
    "message": "Stopping Expo server",
  },
  "mcp_restart_expo_server": {
    "arg": "port",
    "body": "confirmation",
    "message": "Restarting Expo server",
  },
  "mcp_expo_server_status": {
    "arg": "",
    "body": "map[status, url, port]",
    "message": "Checking Expo server status",
  },
  "mcp_install_expo_dependencies": {
    "arg": "",
    "body": "terminal",
    "message": "Installing Expo dependencies",
  },
  "mcp_expo_doctor": {
    "arg": "",
    "body": "editor",
    "message": "Running Expo diagnostics",
  },
  "mcp_clear_expo_cache": {
    "arg": "",
    "body": "confirmation",
    "message": "Clearing Expo cache",
  },
  "mcp_expo_prebuild": {
    "arg": "platform_choice",
    "body": "terminal",
    "message": "Prebuilding for {platform_choice}",
  },
};
