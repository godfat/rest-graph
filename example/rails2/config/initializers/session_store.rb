# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails2_session',
  :secret      => 'c99a19ce0dc4ed1809e32b6b43bd9229c3a504c456230119dd445fdcb63c0ce06b436f1bf1eace27ebbe0da6041ff2b65cbb4ae4beadc3077e3e6ae07ea75118'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
