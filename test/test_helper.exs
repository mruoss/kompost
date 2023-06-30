DotenvParser.load_file("test/integration/.env")
Application.ensure_all_started([:k8s, :postgrex, :db_connection])
ExUnit.start(exclude: [:integration, :e2e, :skip])
