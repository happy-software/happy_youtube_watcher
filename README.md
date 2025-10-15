# Happy Youtube Watcher

Happy Youtube Watcher manages tracked Youtube playlists and their histories over time.

# Problem

Rewatching old Youtube playlists can cause a trip backwards in time, great memories rush back.
Over time, videos in our playlists are deleted or become no longer available in our country.
Youtube won't tell you anything about what that video was, only that it's now gone.

The solution? Happy Youtube Watcher.

# Setup

1. Install ruby.

2. Install postgresql/setup user account.

3. Install `bundler` gem to manage all gems.

4. Run `bundle install` to install required gems.

5. Create an `.env` file in the root directory of the project (see [dotenv](https://github.com/bkeepers/dotenv) for more details) and set these local env vars:
    - DB_USERNAME
    - DB_PASSWORD
    - DB_HOST (optional)
    - DB_PORT (optional)
    - YT_API_KEY (required for youtube api calls)

6. Run `rails db:setup` to setup the database

# Running a development server
```sh
bin/dev
```

# Debugging (VSCode)

1. Install `debase` and `ruby-debug-ide` gems.

2. Start a debug instance of your code: `rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 1234 -- bin/rails s -p 8000`

3. Install `Ruby` extension on vscode

4. Launch a debug listener session in vscode: `Listen for rdebug-ide`

5. Set a breakpoint

6. Execute code to hit breakpoint
