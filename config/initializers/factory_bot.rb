# Only load factories from test/factories (not spec/factories)
# This prevents duplicate factory errors when both directories exist.
FactoryBot.definition_file_paths = [ "test/factories" ] if defined?(FactoryBot)
