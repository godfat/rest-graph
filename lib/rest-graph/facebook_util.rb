
require 'rest-graph/core'

module RestGraph::FacebookUtil
  PERMISSIONS = %w[
    publish_stream
    create_event
    rsvp_event
    sms
    offline_access
    publish_checkins

    user_about_me             friends_about_me
    user_activities           friends_activities
    user_birthday             friends_birthday
    user_education_history    friends_education_history
    user_events               friends_events
    user_groups               friends_groups
    user_hometown             friends_hometown
    user_interests            friends_interests
    user_likes                friends_likes
    user_location             friends_location
    user_notes                friends_notes
    user_online_presence      friends_online_presence
    user_photo_video_tags     friends_photo_video_tags
    user_photos               friends_photos
    user_relationships        friends_relationships
    user_relationship_details friends_relationship_details
    user_religion_politics    friends_religion_politics
    user_status               friends_status
    user_videos               friends_videos
    user_website              friends_website
    user_work_history         friends_work_history
    email
    read_friendlists          manage_friendlists
    read_insights
    read_mailbox
    read_requests
    read_stream
    xmpp_login
    ads_management
    user_checkins             friends_checkins

    manage_pages
  ]

  USER_PERMISSIONS = PERMISSIONS.reject{|perm| perm.start_with?('friends_')}

  def fix_fql_multi result
    result.inject({}){ |r, i| r[i['name']] = i['fql_result_set']; r }
  end

  def fix_permissions result
    # Hash[] is for ruby 1.8.7
    result.first && Hash[result.first.select{ |k, v| v == 1 }].keys
  end

  def permissions uid, selected_permissions=PERMISSIONS
    fix_permissions(
      fql(permissions_fql(uid, selected_permissions), {}, :secret => true))
  end

  def user_permissions uid
    permissions(uid, USER_PERMISSIONS)
  end

  def permissions_fql uid, selected_permissions=PERMISSIONS
    sanitized_uid = uid.to_s.tr("'", '')
    selected      = selected_permissions.join(',')
    "SELECT #{selected} FROM permissions where uid = '#{sanitized_uid}'"
  end
end

RestGraph.send(:include, RestGraph::FacebookUtil)
